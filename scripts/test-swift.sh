#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/env.sh"

"$ROOT_DIR/scripts/build-rust-core.sh" debug
"$ROOT_DIR/scripts/generate.sh"

xcodebuild test \
  -workspace DarkRoom.xcworkspace \
  -scheme DarkRoom \
  -destination 'platform=macOS' \
  -derivedDataPath "$ROOT_DIR/.build/DerivedData"
