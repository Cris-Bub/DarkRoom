#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/env.sh"

cat <<'EOF'
DarkRoom setup is intentionally conservative.

Required:
- Full Xcode or Apple command line tools
- Swift
- Rust stable
- Tuist preferred, XcodeGen fallback

This script verifies and recommends. It does not install global tools for you.
EOF

"$ROOT_DIR/scripts/doctor.sh"
