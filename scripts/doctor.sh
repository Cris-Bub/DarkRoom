#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/env.sh"

failures=0

ok() {
  printf '[ok] %s\n' "$1"
}

warn() {
  printf '[warn] %s\n' "$1"
}

fail() {
  printf '[fail] %s\n' "$1"
  failures=$((failures + 1))
}

require_command() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 found"
  else
    fail "$1 missing"
  fi
}

require_command xcodebuild
require_command xcrun
require_command swift
require_command rustc
require_command cargo

if [ -n "${DEVELOPER_DIR:-}" ]; then
  ok "DEVELOPER_DIR: $DEVELOPER_DIR"
elif xcode-select -p >/dev/null 2>&1; then
  ok "developer directory: $(xcode-select -p)"
else
  fail "xcode-select has no active developer directory"
fi

if xcodebuild -version >/dev/null 2>&1; then
  ok "$(xcodebuild -version | tr '\n' ' ')"
else
  fail "xcodebuild cannot use the active developer directory"
fi

if command -v tuist >/dev/null 2>&1; then
  ok "tuist found"
elif command -v xcodegen >/dev/null 2>&1; then
  ok "xcodegen found"
else
  warn "no project generator found; install Tuist first or XcodeGen as fallback before generating the macOS workspace"
fi

if metal_path="$(xcrun -find metal 2>/dev/null)"; then
  ok "metal compiler found: $metal_path"
else
  warn "metal compiler not found through xcrun; full Xcode may be required for shader work"
fi

if cargo metadata --no-deps >/dev/null 2>&1; then
  ok "cargo workspace readable"
else
  fail "cargo workspace metadata failed"
fi

if [ "$failures" -eq 0 ]; then
  ok "doctor completed"
  exit 0
fi

printf '\n%s\n' "Doctor found $failures blocking issue(s)."
exit 1
