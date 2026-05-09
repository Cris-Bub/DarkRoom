# Repository Spec

## Purpose

The repository root defines the DarkRoom project contract: product direction, licensing, agent rules, development scripts, generated-project configuration, Swift app source, Rust engine source, docs, fixtures, and shader assets.

## Depends On

- macOS development tooling through Xcode command line tools or full Xcode.
- Rust stable toolchain for engine crates.
- Tuist first, or XcodeGen as a fallback, for generated native project files.
- Local files only for baseline tests and fixtures.

## Affords

- A Cursor-first development surface with stable scripts.
- A clear split between native macOS shell code and portable Rust engine code.
- Documentation and `SPEC.md` files that preserve subsystem intent for future agents.

## Responsibilities

- Keep top-level project files small and directional.
- Route implementation into `apps/`, `crates/`, `shaders/`, `fixtures/`, and `scripts/`.
- Keep docs close enough to architecture decisions that changes can be reviewed against intent.

## Boundaries

- Do not put application source directly at the repository root.
- Do not commit generated build output or generated Xcode workspaces.
- Do not let one root-level document become the only source of subsystem truth.

## Update Triggers

Update this spec when a top-level folder is added, removed, renamed, or given a new responsibility.
