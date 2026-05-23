#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${KAIZEN_REPO_DIR:-$HOME/Kaizen-Linux}"
BRANCH="${KAIZEN_BRANCH:-main}"
TARGET_USER="${SUDO_USER:-$USER}"

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Kaizen repo not found at: $REPO_DIR"
  echo "Clone it first with:"
  echo "git clone https://github.com/Aetherelic/Kaizen-Linux.git $REPO_DIR"
  exit 1
fi

cd "$REPO_DIR"

git fetch origin
git switch "$BRANCH"
git reset --hard "origin/$BRANCH"

sudo bash scripts/install-kaizen-desktop.sh "$TARGET_USER"

echo
echo "Kaizen update complete."
echo "Reboot recommended if packages, services, or session configs changed."
