# ToneLab Spec

## Purpose

`ToneLab/` contains the debug-only developer UI for visually tuning DarkRoom V1 behavior constants against a real selected image.

## Depends On

- SwiftUI and AppKit for the debug window and clipboard export.
- `EditGraph/` for `EditRecipe`, `ToneTuning`, `BehaviorTuning`, and overlay selection values.
- `Viewer/` and `ImagePipeline/` for the same color-managed preview path used by the normal app.
- `DesignSystem/` for existing control styling.

## Affords

- A separate developer window that can use the current selected image.
- Local, non-persisted normal light sliders for testing user-facing recipe values.
- Mutable hidden behavior constants that can be copied or saved as JSON and later baked into Rust and Swift defaults.
- Affected-range and diagnostic overlays for tonal controls using the same renderer influence, color-coupling, and overlay tuning parameters as preview.
- Section-level resets for test recipe values and each hidden tuning group.
- Solo and sweep controls for judging each visible slider from subtle to extreme settings.

## Responsibilities

- Keep Tone Lab out of release UI surfaces.
- Keep tuning constants separate from user edit recipes and sidecar persistence.
- Favor fast visual iteration over polished end-user presentation.
- Route preview rendering through the existing viewer/image pipeline instead of inventing a second tone renderer.
- Keep section resets local to the visible Tone Lab group instead of changing unrelated tuning constants.
- Keep per-slider mapping, exposure feel, endpoint range, color-coupling, and overlay experiments wired through `BehaviorTuning` so Rust remains the source of truth for mapping visible slider values into renderer parameters.

## Boundaries

- Do not persist user recipes from this tool.
- Do not write candidate files until a real candidate-management workflow exists.
- Do not put portable tone math here; add math behavior to `darkroom_core` and bridge it through `EditGraph/`.
- Do not tune display profiles, preview target definitions, or RAW decode policy here.

## Update Triggers

Update when Tone Lab gains candidate storage, fixture workflows, graph diagnostics, new tuning surfaces, or changes to exported behavior JSON.
