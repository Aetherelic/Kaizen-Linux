#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${1:-${SUDO_USER:-$USER}}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$EUID" -ne 0 ]; then
  echo "Run with: sudo bash scripts/install-kaizen-desktop.sh <username>"
  exit 1
fi

if [ ! -f /etc/os-release ]; then
  echo "Could not detect OS."
  exit 1
fi

. /etc/os-release

if [ "${ID:-}" != "fedora" ] && ! printf '%s\n' "${ID_LIKE:-}" | grep -qw "fedora"; then
  echo "This script is intended for Fedora or Fedora-based Kaizen Linux."
  exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
  echo "Could not find home directory for user: $TARGET_USER"
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

  if [ -d "$ROOT_DIR/configs/$name" ] && [ "$(find "$ROOT_DIR/configs/$name" -mindepth 1 | wc -l)" -gt 0 ]; then
    mkdir -p "$TARGET_HOME/.config/$name"
    rsync -a --delete "$ROOT_DIR/configs/$name/." "$TARGET_HOME/.config/$name/"
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/$name"
  fi
}

install_wallpapers() {
  if [ -d "$ROOT_DIR/branding/wallpapers" ] && [ "$(find "$ROOT_DIR/branding/wallpapers" -mindepth 1 | wc -l)" -gt 0 ]; then
    mkdir -p "$TARGET_HOME/.local/share/backgrounds/kaizen"
    cp -r "$ROOT_DIR/branding/wallpapers/." "$TARGET_HOME/.local/share/backgrounds/kaizen/"
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/share/backgrounds/kaizen"
  fi
}


install_kaizen_os_branding() {
  if [ -f "$ROOT_DIR/branding/os/os-release" ]; then
    cp "$ROOT_DIR/branding/os/os-release" /usr/lib/os-release
    ln -sf ../usr/lib/os-release /etc/os-release
  fi

  printf "Kaizen Linux\n" > /etc/fedora-release
  printf "Kaizen Linux\n" > /etc/redhat-release
  printf "Kaizen Linux\n" > /etc/system-release
  printf "Kaizen Linux\n" > /etc/issue
  printf "Kaizen Linux\n" > /etc/issue.net
  printf "Kaizen Linux\n\n" > /etc/motd

  hostnamectl set-hostname kaizen 2>/dev/null || true
}



install_kaizen_update_command() {
  mkdir -p /usr/local/bin

  cat > /usr/local/bin/kaizen-update <<'UPDATE'
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${KAIZEN_REPO_DIR:-$HOME/Kaizen-Linux}"
BRANCH="${KAIZEN_BRANCH:-main}"

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Kaizen repo not found. Cloning into: $REPO_DIR"
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone https://github.com/Aetherelic/Kaizen-Linux.git "$REPO_DIR"
fi

cd "$REPO_DIR"

git fetch origin

if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  git checkout -B "$BRANCH" "origin/$BRANCH"
else
  echo "Branch not found on origin: $BRANCH"
  echo "Available remote branches:"
  git branch -r
  exit 1
fi

git reset --hard "origin/$BRANCH"

sudo bash scripts/install-kaizen-desktop.sh "$USER"

if [ -x "$HOME/.config/hypr/scripts/kaizen-generate-theme.sh" ]; then
  bash "$HOME/.config/hypr/scripts/kaizen-generate-theme.sh" "$HOME/.config/hypr/current_wallpaper" || true
fi

echo
echo "Kaizen update complete."
echo "Reboot recommended."
UPDATE

  chmod 755 /usr/local/bin/kaizen-update
}




install_kaizen_welcome() {
  mkdir -p /usr/share/kaizen/welcome /usr/share/applications
  cp -r "$ROOT_DIR/docs/welcome/." /usr/share/kaizen/welcome/

  cat > /usr/local/bin/kaizen-welcome <<'WELCOME'
#!/usr/bin/env bash
set -u

PAGE="/usr/share/kaizen/welcome/index.html"
LOG="/tmp/kaizen-welcome.log"

{
  echo "Kaizen Welcome launched: $(date)"
  echo "USER=$USER"
  echo "DISPLAY=${DISPLAY:-}"
  echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
  echo "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-}"
  echo "PAGE=$PAGE"
} > "$LOG"

if command -v firefox >/dev/null 2>&1; then
  exec firefox "file://$PAGE" >> "$LOG" 2>&1
fi

if command -v xdg-open >/dev/null 2>&1; then
  exec xdg-open "$PAGE" >> "$LOG" 2>&1
fi

if command -v gio >/dev/null 2>&1; then
  exec gio open "$PAGE" >> "$LOG" 2>&1
fi

if command -v kitty >/dev/null 2>&1; then
  exec kitty -e bash -lc "echo 'Could not open Kaizen Welcome.'; echo; cat '$LOG'; echo; read -rp 'Press Enter to close...'"
fi

cat "$LOG"
exit 1
WELCOME

  chmod 755 /usr/local/bin/kaizen-welcome

  cat > /usr/share/applications/kaizen-welcome.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Welcome to Kaizen Linux
Comment=Learn the basics of Kaizen Linux
Exec=/usr/local/bin/kaizen-welcome
Icon=help-about
Terminal=false
Categories=System;Utility;
StartupNotify=true
DESKTOP
}



install_kaizen_profile_tools() {
  mkdir -p /usr/local/bin /usr/share/applications

  cp "$ROOT_DIR/scripts/kaizen-install-profile.sh" /usr/local/bin/kaizen-install-profile
  chmod 755 /usr/local/bin/kaizen-install-profile

  cat > /usr/share/applications/kaizen-install-gaming.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Install Kaizen Gaming Profile
Comment=Install Steam, Lutris, Wine, MangoHud, GameMode, and gaming tools
Exec=kitty -e bash -lc "kaizen-install-profile gaming; echo; read -rp 'Press Enter to close...'"
Icon=applications-games
Terminal=false
Categories=Game;System;
DESKTOP

  cat > /usr/share/applications/kaizen-install-productivity.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Install Kaizen Productivity Profile
Comment=Install office, development, and productivity tools
Exec=kitty -e bash -lc "kaizen-install-profile productivity; echo; read -rp 'Press Enter to close...'"
Icon=applications-office
Terminal=false
Categories=Office;System;
DESKTOP
}


dnf install -y dnf-plugins-core git curl wget

dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${VERSION_ID}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${VERSION_ID}.noarch.rpm" || true

dnf copr enable -y ashbuk/Hyprland-Fedora || true

install_package_list "$ROOT_DIR/packages/base.txt"
install_package_list "$ROOT_DIR/packages/desktop-common.txt"
install_package_list "$ROOT_DIR/packages/display-manager.txt"
install_package_list "$ROOT_DIR/packages/visual.txt"
install_optional_package_list "$ROOT_DIR/packages/noobie-essentials.txt"
install_package_list "$ROOT_DIR/packages/hyprland.txt"
install_optional_package_list "$ROOT_DIR/packages/wallpaper-optional.txt"

copy_config_dir hypr
copy_config_dir kitty
copy_config_dir rofi
copy_config_dir waybar
copy_config_dir fastfetch
copy_config_dir starship
install_wallpapers
install_kaizen_os_branding
install_kaizen_update_command
install_kaizen_welcome
install_kaizen_profile_tools

systemctl disable gdm.service 2>/dev/null || true
systemctl enable sddm.service || true
systemctl set-default graphical.target || true

if [ "${#FAILED_PACKAGES[@]}" -gt 0 ]; then
  printf 'Required packages failed:\n'
  printf ' - %s\n' "${FAILED_PACKAGES[@]}"
  exit 1
fi

if [ "${#OPTIONAL_FAILED_PACKAGES[@]}" -gt 0 ]; then
  printf 'Optional packages skipped:\n'
  printf ' - %s\n' "${OPTIONAL_FAILED_PACKAGES[@]}"
fi


if [ -d "$ROOT_DIR/configs/applications" ]; then
  mkdir -p /usr/share/applications
  install -m 0644 "$ROOT_DIR"/configs/applications/*.desktop /usr/share/applications/ 2>/dev/null || true
fi

printf '\nKaizen desktop install complete. Reboot, then choose Hyprland from the login screen.\n'
