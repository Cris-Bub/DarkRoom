#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROFILE="${1:-debug}"
mkdir -p "$ROOT_DIR/target/debug" "$ROOT_DIR/target/release"

case "$PROFILE" in
  debug)
    cargo build -p darkroom_core
    ;;
  release)
    cargo build -p darkroom_core --release
    ;;
  *)
    printf 'Unknown Rust core build profile: %s\n' "$PROFILE" >&2
    exit 2
    ;;
esac
