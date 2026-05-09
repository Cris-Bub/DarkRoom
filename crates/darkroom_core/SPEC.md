# darkroom_core Spec

## Purpose

`darkroom_core` is the first portable Rust crate. It owns core edit recipe primitives and CPU reference math that future UI and GPU paths can validate against.

## Depends On

- Rust standard library.
- No external crates yet.

## Affords

- Scene-linear exposure reference behavior.
- Pivoted contrast reference behavior.
- V1 light recipe parameter mapping for exposure, contrast, bounded highlights, and bounded shadows.
- C ABI exports that the macOS target can link against for light-control parameter math.
- A minimal light recipe model for early edit graph work.

## Responsibilities

- Keep core math deterministic and well tested.
- Keep shadow/highlight tone shaping monotonic and bounded so extreme settings cannot invert tonal order.
- Prefer small functions with direct tests before broader graph abstractions.
- Provide behavior that Swift and future shader paths can match.
- Keep exported C ABI functions small and stable so Swift can lean on Rust without making UI code own formula decisions.

## Boundaries

- Do not add UI state.
- Do not add platform file access.
- Do not add GPU-only behavior without CPU reference expectations.

## Update Triggers

Update when new edit operations, serialization choices, C ABI boundaries, public API boundaries, or engine dependencies are added.
