#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"

start_waybar() {
  pkill waybar 2>/dev/null || true
  sleep 0.2
  waybar > "$HOME/.cache/kaizen-waybar.log" 2>&1 & disown
}

start_quickshell() {
  pkill quickshell 2>/dev/null || true
  sleep 0.2
  QML_XHR_ALLOW_FILE_READ=1 quickshell --path "$HOME/.config/quickshell/shell.qml" > "$HOME/.cache/kaizen-quickshell.log" 2>&1 & disown
}

case "$MODE" in
  enable)
    pkill waybar 2>/dev/null || true
    start_quickshell
    notify-send "Kaizen Adaptive Mode" "Quickshell enabled" 2>/dev/null || true
    ;;

  disable)
    pkill quickshell 2>/dev/null || true
    start_waybar
    notify-send "Kaizen Adaptive Mode" "Waybar restored" 2>/dev/null || true
    ;;

  restart)
    pkill quickshell 2>/dev/null || true
    start_quickshell
    notify-send "Kaizen Adaptive Mode" "Quickshell restarted" 2>/dev/null || true
    ;;

  status)
    if pgrep -x quickshell >/dev/null 2>&1; then
      echo "Adaptive Mode: enabled"
    else
      echo "Adaptive Mode: disabled"
    fi
    ;;

  *)
    echo "Usage: kaizen-quickshell-mode enable|disable|restart|status"
    exit 1
    ;;
esac
