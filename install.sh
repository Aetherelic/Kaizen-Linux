#!/usr/bin/env bash
set -euo pipefail

INSTALL_HYPRLAND=1
INSTALL_GAMING=1
INSTALL_PRODUCTIVITY=1
ENABLE_THIRD_PARTY=1

FAILED_PACKAGES=()
OPTIONAL_FAILED_PACKAGES=()

usage() {
  cat <<'HELP'
AetherOS Fedora Hyprland installer

Usage:
  ./install.sh [options]

Options:
  --no-hyprland       Do not install Hyprland/COPR packages
  --no-gaming         Do not install gaming packages
  --no-productivity   Do not install productivity packages
  --no-third-party    Do not enable third-party repos/COPRs
  --help              Show this help
HELP
}

for arg in "$@"; do
  case "$arg" in
    --no-hyprland) INSTALL_HYPRLAND=0 ;;
    --no-gaming) INSTALL_GAMING=0 ;;
    --no-productivity) INSTALL_PRODUCTIVITY=0 ;;
    --no-third-party) ENABLE_THIRD_PARTY=0 ;;
    --help) usage; exit 0 ;;
    *) printf "Unknown option: %s\n" "$arg"; usage; exit 1 ;;
  esac
done

if ! command -v dnf >/dev/null 2>&1; then
  printf "This installer is for Fedora-based systems only.\n"
  exit 1
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  printf "Could not detect OS.\n"
  exit 1
fi

case "${ID:-}" in
  fedora) ;;
  *)
    printf "This installer currently supports Fedora only. Detected: %s\n" "${ID:-unknown}"
    exit 1
    ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_package_list() {
  local file="$1"

  [ -f "$file" ] || return 0

  while IFS= read -r pkg; do
    case "$pkg" in
      ""|\#*) continue ;;
    esac

    if ! sudo dnf install -y "$pkg"; then
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

    if ! sudo dnf install -y "$pkg"; then
      OPTIONAL_FAILED_PACKAGES+=("$pkg")
    fi
  done < "$file"
}

install_flatpak_list() {
  local file="$1"

  [ -f "$file" ] || return 0
  command -v flatpak >/dev/null 2>&1 || return 0

  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

  while IFS= read -r app; do
    case "$app" in
      ""|\#*) continue ;;
    esac

    flatpak install -y flathub "$app" || true
  done < "$file"
}

copy_config_dir() {
  local name="$1"

  if [ -d "$ROOT_DIR/configs/$name" ] && [ "$(find "$ROOT_DIR/configs/$name" -mindepth 1 | wc -l)" -gt 0 ]; then
    mkdir -p "$HOME/.config"
    rm -rf "$HOME/.config/$name"
    cp -r "$ROOT_DIR/configs/$name" "$HOME/.config/$name"
  fi
}

sudo dnf upgrade --refresh -y
sudo dnf install -y dnf-plugins-core

if [ "$ENABLE_THIRD_PARTY" -eq 1 ]; then
  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${VERSION_ID}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${VERSION_ID}.noarch.rpm" || true

  if [ "$INSTALL_HYPRLAND" -eq 1 ]; then
    sudo dnf copr enable -y ashbuk/Hyprland-Fedora || true
  fi
fi

sudo dnf group upgrade -y core || true

install_package_list "$ROOT_DIR/packages/base.txt"
install_package_list "$ROOT_DIR/packages/desktop-common.txt"
install_optional_package_list "$ROOT_DIR/packages/wallpaper-optional.txt"

if [ "$INSTALL_HYPRLAND" -eq 1 ]; then
  install_package_list "$ROOT_DIR/packages/hyprland.txt"
fi

if [ "$INSTALL_GAMING" -eq 1 ]; then
  install_package_list "$ROOT_DIR/packages/gaming.txt"
fi

if [ "$INSTALL_PRODUCTIVITY" -eq 1 ]; then
  install_package_list "$ROOT_DIR/packages/productivity-dnf.txt"
  install_flatpak_list "$ROOT_DIR/packages/productivity-flatpak.txt"
fi

copy_config_dir hypr
copy_config_dir quickshell
copy_config_dir rofi
copy_config_dir kitty
copy_config_dir fastfetch
copy_config_dir starship

systemctl --user daemon-reload 2>/dev/null || true

printf "\nAetherOS Fedora Hyprland base install complete.\n"

if [ "${#FAILED_PACKAGES[@]}" -gt 0 ]; then
  printf "\nSome required packages failed to install and need review:\n"
  printf ' - %s\n' "${FAILED_PACKAGES[@]}"
fi

if [ "${#OPTIONAL_FAILED_PACKAGES[@]}" -gt 0 ]; then
  printf "\nSome optional packages were skipped:\n"
  printf ' - %s\n' "${OPTIONAL_FAILED_PACKAGES[@]}"
fi

printf "\nReboot, then choose Hyprland from your login screen if available.\n"
