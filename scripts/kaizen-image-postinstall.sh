#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${1:-kaizen}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v dnf >/dev/null 2>&1; then
  echo "This script must be run inside a Fedora image/root."
  exit 1
fi

if [ ! -f /etc/os-release ]; then
  echo "Could not detect OS."
  exit 1
fi

. /etc/os-release

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
  echo "Could not find home directory for user: $TARGET_USER"
  exit 1
fi

install_package_list() {
  local file="$1"

  [ -f "$file" ] || return 0

  while IFS= read -r pkg; do
    case "$pkg" in
      ""|\#*) continue ;;
    esac

    dnf install -y "$pkg"
  done < "$file"
}

install_calamares_config() {
  if [ -d "$ROOT_DIR/configs/calamares" ] && [ "$(find "$ROOT_DIR/configs/calamares" -mindepth 1 | wc -l)" -gt 0 ]; then
    mkdir -p /etc/calamares
    rm -rf /etc/calamares/modules /etc/calamares/branding
    cp -a "$ROOT_DIR/configs/calamares/." /etc/calamares/
  fi
}

install_installer_shortcut() {
  mkdir -p /usr/local/bin /etc/sudoers.d /usr/share/applications "$TARGET_HOME/Desktop" "$TARGET_HOME/.local/share/applications"

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
else
  cat "$LOG"
fi

exit 1
USERWRAP

  chmod 755 /usr/local/bin/kaizen-calamares-root /usr/local/bin/install-kaizen-linux

  cat > /etc/sudoers.d/kaizen-installer <<SUDOERS
${TARGET_USER} ALL=(root) NOPASSWD:SETENV: /usr/local/bin/kaizen-calamares-root, /usr/bin/calamares
SUDOERS

  chmod 440 /etc/sudoers.d/kaizen-installer

  for f in /usr/share/applications/*calamares*.desktop /usr/share/applications/*installer*.desktop; do
    if [ -f "$f" ] && grep -qiE 'calamares|Install System' "$f"; then
      sed -i '/^NoDisplay=/d;/^Hidden=/d' "$f"
      sed -i '/^\[Desktop Entry\]/a Hidden=true\nNoDisplay=true' "$f"
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

  cp /usr/share/applications/install-kaizen-linux.desktop "$TARGET_HOME/Desktop/install-kaizen-linux.desktop"
  cp /usr/share/applications/install-kaizen-linux.desktop "$TARGET_HOME/.local/share/applications/install-kaizen-linux.desktop"

  chmod +x /usr/share/applications/install-kaizen-linux.desktop "$TARGET_HOME/Desktop/install-kaizen-linux.desktop" "$TARGET_HOME/.local/share/applications/install-kaizen-linux.desktop"
  chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/Desktop" "$TARGET_HOME/.local/share/applications"
}

configure_live_iso_session() {
  mkdir -p /etc/sudoers.d /etc/sddm.conf.d

  cat > /etc/sudoers.d/kaizen-live <<SUDOERS
${TARGET_USER} ALL=(ALL) NOPASSWD: ALL
SUDOERS

  chmod 440 /etc/sudoers.d/kaizen-live

  cat > /etc/sddm.conf.d/10-kaizen-autologin.conf <<SDDM
[Autologin]
User=${TARGET_USER}
Session=hyprland.desktop
Relogin=false

[Users]
RememberLastUser=true
RememberLastSession=true
SDDM

  systemctl enable sshd.service 2>/dev/null || true
  systemctl enable qemu-guest-agent.service 2>/dev/null || true
  systemctl enable spice-vdagentd.service 2>/dev/null || true

  systemctl disable gdm.service 2>/dev/null || true
  systemctl enable sddm.service || true
  systemctl set-default graphical.target || true
}


# Install Kaizen user defaults into /etc/skel so Calamares-created users inherit them.
if [ -d "$ROOT_DIR/configs" ]; then
  mkdir -p /etc/skel/.config
  for name in hypr waybar rofi kitty fastfetch swaync starship; do
    if [ -d "$ROOT_DIR/configs/$name" ]; then
      rm -rf "/etc/skel/.config/$name"
      mkdir -p "/etc/skel/.config/$name"
      cp -a "$ROOT_DIR/configs/$name/." "/etc/skel/.config/$name/"
    fi
  done
  chown -R root:root /etc/skel/.config
fi

if [ -d "$ROOT_DIR/branding/wallpapers" ]; then
  mkdir -p /etc/skel/.local/share/backgrounds/kaizen
  cp -a "$ROOT_DIR/branding/wallpapers/." /etc/skel/.local/share/backgrounds/kaizen/
  chown -R root:root /etc/skel/.local
fi

bash "$ROOT_DIR/scripts/install-kaizen-desktop.sh" "$TARGET_USER"

install_package_list "$ROOT_DIR/packages/installer.txt"

install_calamares_config
install_installer_shortcut
configure_live_iso_session

chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config" "$TARGET_HOME/.local" 2>/dev/null || true

echo
echo "Kaizen image postinstall complete."
