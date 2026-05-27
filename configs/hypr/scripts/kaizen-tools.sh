#!/usr/bin/env bash
set -euo pipefail

ROFI_THEME="$HOME/.config/rofi/kaizen-adaptive.rasi"

choice="$(
  cat <<'MENU' | rofi -dmenu -i -p "Kaizen Tools" -theme "$ROFI_THEME"
◆  Welcome to Kaizen
↻  Update Kaizen
▣  Wallpaper Picker
▤  System Monitor
◇  Disk Utility
◉  Audio Settings
◎  Bluetooth Settings
◌  Network Settings
✦  Install Gaming Profile
✧  Install Productivity Profile
◇  Enable Adaptive Mode
◆  Disable Adaptive Mode
?  Help / Keybinds
ⓘ  About Kaizen
MENU
)"

case "$choice" in
  "◆  Welcome to Kaizen")
    kaizen-welcome
    ;;

  "↻  Update Kaizen")
    kitty -e bash -lc 'KAIZEN_BRANCH="${KAIZEN_BRANCH:-full-rice-integration}" kaizen-update; echo; read -rp "Press Enter to close..."'
    ;;

  "▣  Wallpaper Picker")
    bash "$HOME/.config/hypr/scripts/kaizen-wallpaper-picker.sh"
    ;;

  "▤  System Monitor")
    gnome-system-monitor >/dev/null 2>&1 &
    ;;

  "◇  Disk Utility")
    gnome-disks >/dev/null 2>&1 &
    ;;

  "◉  Audio Settings")
    pavucontrol >/dev/null 2>&1 &
    ;;

  "◎  Bluetooth Settings")
    blueman-manager >/dev/null 2>&1 &
    ;;

  "◌  Network Settings")
    kitty -e nmtui
    ;;

  "✦  Install Gaming Profile")
    kitty -e bash -lc 'kaizen-install-profile gaming; echo; read -rp "Press Enter to close..."'
    ;;

  "✧  Install Productivity Profile")
    kitty -e bash -lc 'kaizen-install-profile productivity; echo; read -rp "Press Enter to close..."'
    ;;

  "◇  Enable Adaptive Mode")
    kaizen-quickshell-mode enable
    ;;

  "◆  Disable Adaptive Mode")
    kaizen-quickshell-mode disable
    ;;

  "?  Help / Keybinds")
    kitty -e bash -lc 'bash "$HOME/.config/hypr/scripts/kaizen-keybinds.sh"; echo; read -rp "Press Enter to close..."'
    ;;

  "ⓘ  About Kaizen")
    kitty -e bash -lc 'cat /etc/os-release; echo; echo "Repo: https://github.com/Aetherelic/Kaizen-Linux"; echo; read -rp "Press Enter to close..."'
    ;;
esac
