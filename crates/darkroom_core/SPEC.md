# darkroom_core Spec

## Purpose

`darkroom_core` is the first portable Rust crate. It owns core edit recipe primitives and CPU reference math that future UI and GPU paths can validate against.

## Depends On

- Rust standard library.
- No external crates yet.

## Affords

- Scene-linear exposure reference behavior.
- Legacy pivoted contrast reference behavior kept for focused math tests.
- V1 `darkroom_tonal_curve_v1` recipe parameter mapping for exposure, contrast, pivot, bounded highlights, bounded shadows, whites, and blacks.
- V1 `ToneTuning` and Tone Lab V2 `BehaviorTuning` defaults plus tuning-to-kernel mapping for developer experiments, including per-slider response mappings, endpoint range width, exposure feel, color coupling, and overlay parameters.
- C ABI exports that the macOS target can link against for tonal parameter math, histogram binning, and per-pixel tone recipe application used by the interactive histogram fast path.
- A minimal light recipe model for early edit graph work.

## Responsibilities

- Keep core math deterministic and well tested.
- Keep the V1 tonal curve monotonic and bounded so extreme settings cannot invert tonal order.
- Keep production tuning defaults explicit so Tone Lab experiments do not silently change normal app behavior.
- Keep visible slider to renderer-parameter mapping and hidden behavior-tuning derivation in Rust so Swift UI can tune constants without owning response-curve or color-coupling math.
- Keep histogram binning deterministic and fast enough for interactive inspector updates.
- Prefer small functions with direct tests before broader graph abstractions.
- Provide behavior that Swift and future shader paths can match.
- Keep exported C ABI functions small and stable so Swift can lean on Rust without making UI code own formula decisions.

## Boundaries

- Do not add UI state.
- Do not add platform file access.
- Do not add GPU-only behavior without CPU reference expectations.

## Update Triggers

Update when new edit operations, tonal curve versions, serialization choices, C ABI boundaries, public API boundaries, or engine dependencies are added.
