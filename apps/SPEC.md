# Apps Folder Spec

## Purpose

`apps/` contains user-facing application shells. The first shell is the native macOS app.

## Depends On

- Platform-specific SDKs for each app shell.
- Portable engine contracts from `crates/`.
- Shared docs and decisions from `docs/`.

## Affords

- Clear separation between product shells and portable engine code.
- Room for future platform shells without mixing UI concerns into Rust core crates.

## Responsibilities

- Host platform UX.
- Own platform file access, windowing, accessibility, and native settings behavior.
- Bind user controls to engine state without embedding engine math.

## Boundaries

- Do not put portable grading math here.
- Do not put reusable engine schema here unless it is Swift-only UI state.

## Update Triggers

Update when a new app shell is added or when ownership between shell and engine changes.
