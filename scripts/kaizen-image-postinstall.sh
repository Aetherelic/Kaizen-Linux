#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${1:-kaizen}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v dnf >/dev/null 2>&1; then
  echo "This script must be run inside a Fedora image/root."
  exit 1
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "Could not detect OS."
  exit 1
fi

FAILED_PACKAGES=()
OPTIONAL_FAILED_PACKAGES=()

install_package_list() {
  local file="$1"

  [ -f "$file" ] || return 0

  while IFS= read -r pkg; do
    case "$pkg" in
      ""|\#*) continue ;;
    esac

    if ! dnf install -y "$pkg"; then
      FAILED_PACKAGES+=("$pkg")
    fi
  done < "$file"
}

install_optional_package_list() {
  local file="$1"

  [ -f "$file" ] || return 0

  while IFS= read -r pkg; do
    case "$pkg" in
      ""|\#*) continue ;;
    esac

    if ! dnf install -y "$pkg"; then
      OPTIONAL_FAILED_PACKAGES+=("$pkg")
    fi
  done < "$file"
}

copy_config_dir() {
  local name="$1"
  local target_home="$2"

  if [ -d "$ROOT_DIR/configs/$name" ] && [ "$(find "$ROOT_DIR/configs/$name" -mindepth 1 | wc -l)" -gt 0 ]; then
    mkdir -p "$target_home/.config"
    rm -rf "$target_home/.config/$name"
    cp -r "$ROOT_DIR/configs/$name" "$target_home/.config/$name"
  fi
}



install_installer_shortcut() {
  local target_home="$1"
  local target_user
  target_user="$(basename "$target_home")"

  mkdir -p /usr/local/bin /etc/sudoers.d /usr/share/applications "$target_home/Desktop" "$target_home/.local/share/applications"

  cat > /usr/local/bin/kaizen-calamares-root <<'ROOTWRAP'
#!/usr/bin/env bash
set -u

export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export HOME=/root

exec /usr/bin/calamares -d
ROOTWRAP

  cat > /usr/local/bin/install-kaizen-linux <<'USERWRAP'
#!/usr/bin/env bash
set -u

LOG="/tmp/kaizen-installer.log"
: > "$LOG"

{
  date
  echo "User: $(id)"
  echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
  echo "DISPLAY=${DISPLAY:-}"
  echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}"
  echo "QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-}"
} >> "$LOG" 2>&1

export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

if sudo -n -E /usr/local/bin/kaizen-calamares-root >> "$LOG" 2>&1; then
  exit 0
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send "Kaizen installer failed to launch" "Opening debug log..."
fi

if command -v kitty >/dev/null 2>&1; then
  exec kitty -e bash -lc "cat '$LOG'; echo; read -rp 'Press Enter to close...'"
elif command -v xterm >/dev/null 2>&1; then
  exec xterm -e bash -lc "cat '$LOG'; echo; read -rp 'Press Enter to close...'"
else
  cat "$LOG"
fi

exit 1
USERWRAP

  chmod 755 /usr/local/bin/kaizen-calamares-root /usr/local/bin/install-kaizen-linux

  cat > /etc/sudoers.d/kaizen-installer <<SUDOERS
${target_user} ALL=(root) NOPASSWD:SETENV: /usr/local/bin/kaizen-calamares-root, /usr/bin/calamares
SUDOERS

  chmod 440 /etc/sudoers.d/kaizen-installer

  for f in /usr/share/applications/*calamares*.desktop /usr/share/applications/*installer*.desktop; do
    if [ -f "$f" ] && grep -qiE 'calamares|Install System' "$f"; then
      sed -i '/^NoDisplay=/d;/^Hidden=/d' "$f"
      sed -i '/^\[Desktop Entry\]/a Hidden=true
NoDisplay=true' "$f"
    fi
  done

  cat > /usr/share/applications/install-kaizen-linux.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Install Kaizen Linux
Comment=Install Kaizen Linux to disk
Exec=/usr/local/bin/install-kaizen-linux
Icon=system-software-install
Terminal=false
Categories=System;
StartupNotify=true
DESKTOP

  cp /usr/share/applications/install-kaizen-linux.desktop "$target_home/Desktop/install-kaizen-linux.desktop"
  cp /usr/share/applications/install-kaizen-linux.desktop "$target_home/.local/share/applications/install-kaizen-linux.desktop"

  chmod +x /usr/share/applications/install-kaizen-linux.desktop "$target_home/Desktop/install-kaizen-linux.desktop" "$target_home/.local/share/applications/install-kaizen-linux.desktop"
}


install_wallpapers() {
  local target_home="$1"

  if [ -d "$ROOT_DIR/branding/wallpapers" ] && [ "$(find "$ROOT_DIR/branding/wallpapers" -mindepth 1 | wc -l)" -gt 0 ]; then
    mkdir -p "$target_home/.local/share/backgrounds/kaizen"
    cp -r "$ROOT_DIR/branding/wallpapers/." "$target_home/.local/share/backgrounds/kaizen/"
  fi
}


install_calamares_config() {
  if [ -d "$ROOT_DIR/configs/calamares" ] && [ "$(find "$ROOT_DIR/configs/calamares" -mindepth 1 | wc -l)" -gt 0 ]; then
    mkdir -p /etc/calamares
    rm -rf /etc/calamares/modules /etc/calamares/branding
    cp -a "$ROOT_DIR/configs/calamares/." /etc/calamares/
  fi
}



configure_live_installer_session() {
  local target_user="$1"

  mkdir -p /etc/sudoers.d /etc/sddm.conf.d

  cat > /etc/sudoers.d/kaizen-live <<SUDOERS
${target_user} ALL=(ALL) NOPASSWD: ALL
SUDOERS

  chmod 440 /etc/sudoers.d/kaizen-live

  cat > /etc/sddm.conf.d/10-kaizen-autologin.conf <<SDDM
[Autologin]
User=${target_user}
Session=hyprland.desktop

[Users]
RememberLastUser=true
RememberLastSession=true
SDDM
}


dnf install -y dnf-plugins-core git curl wget

dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${VERSION_ID}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${VERSION_ID}.noarch.rpm" || true

dnf copr enable -y ashbuk/Hyprland-Fedora || true

install_package_list "$ROOT_DIR/packages/base.txt"
install_package_list "$ROOT_DIR/packages/desktop-common.txt"
install_package_list "$ROOT_DIR/packages/display-manager.txt"
install_package_list "$ROOT_DIR/packages/installer.txt"
install_package_list "$ROOT_DIR/packages/visual.txt"
install_package_list "$ROOT_DIR/packages/hyprland.txt"
install_optional_package_list "$ROOT_DIR/packages/wallpaper-optional.txt"

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
  echo "Could not find home directory for user: $TARGET_USER"
  exit 1
fi

copy_config_dir hypr "$TARGET_HOME"
copy_config_dir kitty "$TARGET_HOME"
copy_config_dir rofi "$TARGET_HOME"
copy_config_dir waybar "$TARGET_HOME"
copy_config_dir fastfetch "$TARGET_HOME"
copy_config_dir starship "$TARGET_HOME"
install_wallpapers "$TARGET_HOME"
install_installer_shortcut "$TARGET_HOME"
configure_live_installer_session "$TARGET_USER"
install_calamares_config

chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config" "$TARGET_HOME/.local" 2>/dev/null || true

systemctl disable gdm.service 2>/dev/null || true
systemctl enable sddm.service || true
systemctl set-default graphical.target || true

echo
echo "Kaizen image postinstall complete."

if [ "${#FAILED_PACKAGES[@]}" -gt 0 ]; then
  echo
  echo "Required packages failed:"
  printf ' - %s\n' "${FAILED_PACKAGES[@]}"
  exit 1
fi

if [ "${#OPTIONAL_FAILED_PACKAGES[@]}" -gt 0 ]; then
  echo
  echo "Optional packages skipped:"
  printf ' - %s\n' "${OPTIONAL_FAILED_PACKAGES[@]}"
fi
