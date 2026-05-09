# Root File Specs

## `README.md`

Purpose: public project introduction, quickstart, status, and milestone summary.

Depends on: current repository shape and accepted product direction.

Affords: a fast orientation point for contributors and agents.

Update when: project status, quickstart commands, folder structure, milestones, or license details change.

## `Agent.md`

Purpose: canonical operating rules for AI agents working in the repo.

Depends on: repository architecture, script workflow, and spec convention.

Affords: consistent behavior from future agents.

Update when: ownership boundaries, required commands, generated-file policy, or documentation rules change.

## `AGENTS.md`

Purpose: compatibility pointer for tools that look for this conventional filename.

Depends on: `Agent.md`.

Affords: better chance that agents discover the canonical rules.

Update when: the canonical agent file moves or changes name.

## `Project.swift`

Purpose: source-controlled Tuist project definition for the macOS app and tests.

Depends on: Tuist, app source under `apps/macos`, and resource files.

Affords: generated Xcode workspace or project without treating Xcode as the source of truth.

Update when: app targets, bundle IDs, resources, tests, deployment targets, or source paths change.

## `Cargo.toml`

Purpose: root Rust workspace manifest.

Depends on: Rust stable and crates under `crates/`.

Affords: workspace-wide Cargo commands such as `cargo test --workspace`.

Update when: crates are added, removed, renamed, or workspace dependency policy changes.

## `LICENSE`

Purpose: open-source license grant.

Depends on: project ownership policy.

Affords: clear legal terms for reuse and contribution.

Update when: the project changes license or copyright holder naming.
