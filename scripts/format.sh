#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

cargo fmt --all

if command -v swift-format >/dev/null 2>&1; then
  swift-format format --recursive --in-place apps/macos/Sources
else
  printf '%s\n' "swift-format not found; skipping Swift formatting"
fi
