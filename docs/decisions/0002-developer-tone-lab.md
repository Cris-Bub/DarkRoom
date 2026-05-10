# 0002: Developer Tone Lab

## Status

Accepted

## Context

DarkRoom Tonal Curve v1 has technical guardrails for bounded broad-zone tone behavior, but slider feel still needs taste tuning across real images. Repeatedly hard-coding constants makes that work slow and fragile.

## Decision

Add a debug-only Tone Lab window that can use the current selected image, expose local user-facing light sliders, mutate a hidden `ToneTuning` object, preview through the existing color-managed viewer pipeline, show affected-range overlays, and copy the full tuning object as JSON.

Production editing continues to use the current V1 defaults until a candidate is intentionally baked into `ToneTuning.defaultV1` and the Rust default tuning. Tone Lab recipe changes are local test values and do not write sidecars.

## Consequences

- Visible edit recipes stay separate from hidden tuning constants.
- Rust owns the tuning-to-kernel mapping and default production constants.
- Swift owns the developer UI and passes tuning values through the same renderer used by preview and export.
- Candidate storage, fixture selection, curve graphs, and histogram diagnostics remain future additions.
