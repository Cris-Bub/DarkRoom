#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

cargo clippy --workspace --all-targets -- -D warnings

if command -v swift-format >/dev/null 2>&1; then
  swift-format lint --recursive apps/macos/Sources
else
  printf '%s\n' "swift-format not found; skipping Swift lint"
fi
