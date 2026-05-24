# 0002: Developer Tone Lab

## Status

Accepted

## Context

DarkRoom Tonal Curve v1 has technical guardrails for bounded broad-zone tone behavior, but slider feel still needs taste tuning across real images. Repeatedly hard-coding constants makes that work slow and fragile.

## Decision

Add a debug-only Tone Lab window that can use the current selected image, expose local user-facing light sliders, mutate hidden `ToneTuning` and `BehaviorTuning` objects, preview through the existing color-managed viewer pipeline, show affected-range overlays, and copy the full tuning object as JSON.

Production editing continues to use the current V1 defaults until a candidate is intentionally baked into `ToneTuning.defaultV1` and the Rust default tuning. Tone Lab recipe changes are local test values and do not write sidecars.

Dense developer controls should favor explicit manipulation over hidden magic. Numeric tuning sliders get exact per-slider reset buttons plus small `info.circle` popovers. Range-sensitive behavior gets graph editors where practical, including exposure-shadow visibility shaping. Color protection controls are centered on their reset/default value: above default protects or damps chroma shifts, below default loosens the response so a colorist can feel both sides of the behavior.

## Consequences

- Visible edit recipes stay separate from hidden tuning constants.
- Rust owns the tuning-to-kernel mapping and default production constants.
- Swift owns the developer UI and passes tuning values through the same renderer used by preview and export.
- Chroma/saturation controls in Tone Lab must be real renderer-facing behavior. Placeholder controls should either be wired through Rust/Core Image or removed until they can affect preview.
- Fixture selection and histogram diagnostics remain future additions.
