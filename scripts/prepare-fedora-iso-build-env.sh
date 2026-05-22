#!/usr/bin/env bash
set -euo pipefail

if ! command -v dnf >/dev/null 2>&1; then
  printf "This script must be run on Fedora.\n"
  exit 1
fi

sudo dnf install -y \
  lorax \
  pykickstart \
  spin-kickstarts \
  mock \
  git

if ! command -v livemedia-creator >/dev/null 2>&1; then
  printf "livemedia-creator was not found after installing lorax.\n"
  exit 1
fi

if ! command -v ksvalidator >/dev/null 2>&1; then
  printf "ksvalidator was not found after installing pykickstart.\n"
  exit 1
fi

sudo usermod -aG mock "$USER" || true

printf "\nFedora ISO build environment prepared.\n"
printf "Log out and back in if this is the first time adding your user to the mock group.\n"
