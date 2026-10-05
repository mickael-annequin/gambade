#!/usr/bin/env bash
# Android Studio (Windows) can't build reliably inside WSL, so we copy this
# folder to Windows and open the copy's android/ folder in Android Studio.
# Always edit the files here (WSL, under Git), then run this script again.
set -e

WINDOWS_DIR=/mnt/c/Users/micka/AndroidStudioProjects/gambade-mobile

cd "$(dirname "$0")"
npx cap sync android

# node_modules is copied too: the Android project loads Capacitor from it.
# Build outputs and Windows-specific settings stay on the Windows side.
rsync -a --delete \
  --exclude build/ --exclude .gradle/ --exclude .idea/ --exclude local.properties \
  ./ "$WINDOWS_DIR/"

echo "Copié dans C:\\Users\\micka\\AndroidStudioProjects\\gambade-mobile"
