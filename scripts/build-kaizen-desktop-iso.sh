#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v0.1.0-alpha}"
ISO_NAME="Kaizen-Linux-${VERSION}-x86_64.iso"
BUILD_DIR="$HOME/kaizen-desktop-iso-build"
REPO_DIR="$HOME/Kaizen-Linux"

cd "$REPO_DIR"

sudo rm -rf "$BUILD_DIR/result" "$BUILD_DIR/tmp" "$BUILD_DIR/anaconda"
mkdir -p "$BUILD_DIR/tmp"

ksvalidator kickstart/kaizen-desktop.ks

sudo livemedia-creator \
  --make-iso \
  --no-virt \
  --ks "$REPO_DIR/kickstart/kaizen-desktop.ks" \
  --releasever 44 \
  --project "Kaizen Linux" \
  --volid "KAIZEN" \
  --iso-only \
  --iso-name "$ISO_NAME" \
  --resultdir "$BUILD_DIR/result" \
  --tmp "$BUILD_DIR/tmp" \
  --logfile "$BUILD_DIR/livemedia.log"

sha256sum "$BUILD_DIR/result/$ISO_NAME"
