#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$ROOT_DIR/.build/DerivedData/Build/Products/Release/DarkRoom.app"
DIST_DIR="$ROOT_DIR/dist"

"$ROOT_DIR/scripts/build-release.sh"

mkdir -p "$DIST_DIR"

if [ ! -d "$APP_PATH" ]; then
  printf '%s\n' "Release app not found at $APP_PATH"
  exit 1
fi

ditto -c -k --keepParent "$APP_PATH" "$DIST_DIR/DarkRoom-macOS.zip"
printf '%s\n' "Created $DIST_DIR/DarkRoom-macOS.zip"
