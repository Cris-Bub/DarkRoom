#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$ROOT_DIR/.build/DerivedData/Build/Products/Debug/DarkRoom.app"

if [ ! -d "$APP_PATH" ]; then
  printf '%s\n' "Debug app not found at $APP_PATH"
  printf '%s\n' "Run ./scripts/build-debug.sh first."
  exit 1
fi

open "$APP_PATH"
