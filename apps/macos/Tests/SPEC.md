# macOS Tests Spec

## Purpose

`apps/macos/Tests/` contains Swift tests for macOS shell behavior that can be checked through `xcodebuild test`.

## Depends On

- XCTest.
- The `DarkRoom` app target.
- Generated project membership from `Project.swift`.

## Affords

- Regression coverage for folder scanning models, UI state models, bridge calls, and settings behavior.

## Responsibilities

- Test shell behavior without embedding engine math expectations that belong in Rust.
- Keep tests small and deterministic.
- Avoid tests that need a user's real photo folders.

## Boundaries

- Do not store image fixtures here; use `fixtures/`.
- Do not require cloud services or user-specific local state.

## Update Triggers

Update when Swift test ownership, fixture strategy, or bridge test policy changes.
