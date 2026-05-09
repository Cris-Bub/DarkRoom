# macOS Tests Spec

## Purpose

`apps/macos/Tests/` contains Swift tests for macOS shell behavior that can be checked through `xcodebuild test`.

## Depends On

- XCTest.
- The `DarkRoom` app target.
- Generated project membership from `Project.swift`.

## Affords

- Regression coverage for folder scanning models, edit recipes, sidecar persistence, color-pipeline policy, shared image rendering, export writing, RAW decoder contracts, UI state models, bridge calls, and settings behavior.

## Responsibilities

- Test shell behavior without embedding engine math expectations that belong in Rust.
- Test Swift rendering for parity-critical behavioral guarantees such as ordered tonal gradients after extreme light edits.
- Test color-management value objects and decoder interfaces without requiring a user's real photo library.
- Test export and image-pipeline behavior with generated temporary fixtures, not user photos.
- Keep tests small and deterministic.
- Avoid tests that need a user's real photo folders.

## Boundaries

- Do not store image fixtures here; use `fixtures/`.
- Do not require cloud services or user-specific local state.

## Update Triggers

Update when Swift test ownership, color-pipeline fixture strategy, RAW decoder test policy, or bridge test policy changes.
