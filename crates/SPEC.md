# Crates Folder Spec

## Purpose

`crates/` contains Rust workspace members for portable engine behavior.

## Depends On

- Rust stable.
- Root `Cargo.toml` workspace membership.
- Engine architecture docs in `docs/`.

## Affords

- Testable CPU reference behavior for color math, edit graph rules, masks, scopes, presets, and cache/index logic.
- A portable foundation for future platform shells.

## Responsibilities

- Keep math and schemas independent of macOS UI.
- Add focused crates when responsibilities become meaningfully distinct.
- Keep tests close to engine behavior.

## Boundaries

- Do not import AppKit, Swift, or macOS UI assumptions into portable crates.
- Do not hide user-interface behavior inside engine APIs.

## Update Triggers

Update when crates are added, removed, renamed, or when ownership boundaries between Rust crates change.
