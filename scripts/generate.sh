#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/env.sh"

if command -v tuist >/dev/null 2>&1; then
  tuist generate --no-open
  exit 0
fi

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
  exit 0
fi

cat <<'EOF'
No project generator found.

Install Tuist first, or XcodeGen as a fallback, then rerun:
  ./scripts/generate.sh

Rust-only work can continue with:
  ./scripts/test-rust.sh
EOF

exit 1
