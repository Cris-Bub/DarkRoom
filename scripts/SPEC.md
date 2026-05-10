# Scripts Folder Spec

## Purpose

`scripts/` is the stable terminal interface for developing DarkRoom from Cursor or VS Code.

## Depends On

- Bash on macOS.
- Rust toolchain for Rust scripts.
- Xcode command line tools and project generator for macOS app scripts.

## Affords

- Predictable setup, health check, generate, build, run, test, format, lint, package, and clean commands.
- A Rust-core build entrypoint that produces the static library linked by the macOS app.
- A single place to hide tool-specific command details from README and agents.
- A shared environment shim that points scripts at full Xcode when `/Applications/Xcode.app` exists.

## Responsibilities

- Keep scripts small and readable.
- Fail with actionable messages.
- Avoid global system changes unless clearly confirmed by the user outside the script.
- Source `scripts/env.sh` from scripts that need Apple developer tools.
- Build the Rust core before Swift build/test commands that link against it.
- Regenerate the Tuist workspace before Swift build/test commands so new source files are included.

## Boundaries

- Do not encode hidden product logic in scripts.
- Do not delete user photo folders, app libraries, or fixtures from clean scripts.

## Update Triggers

Update when required tooling, Rust library linkage, build products, workspace names, schemes, or test commands change.
