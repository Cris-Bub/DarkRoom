#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

"$ROOT_DIR/scripts/generate.sh"
"$ROOT_DIR/scripts/build-debug.sh"
"$ROOT_DIR/scripts/run.sh"
