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

if [ "${ID:-}" != "fedora" ]; then
  echo "This script is intended for Fedora."
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
  echo "Kaizen repo not found at: $REPO_DIR"
  echo
  echo "Clone it first with:"
  echo "git clone https://github.com/Aetherelic/Kaizen-Linux.git $REPO_DIR"
  exit 1
fi

cd "$REPO_DIR"

git fetch origin
git switch "$BRANCH"
git reset --hard "origin/$BRANCH"

sudo bash scripts/install-kaizen-desktop.sh "$USER"

echo
echo "Kaizen update complete."
echo "Reboot recommended."
UPDATE

  chmod 755 /usr/local/bin/kaizen-update
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

printf '\nKaizen desktop install complete. Reboot, then choose Hyprland from the login screen.\n'
