#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

rm -rf "$ROOT_DIR/.build/DerivedData"
rm -rf "$ROOT_DIR/dist"
rm -rf "$ROOT_DIR/target"

printf '%s\n' "Removed local build artifacts."
