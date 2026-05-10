# ToneLab Spec

## Purpose

`ToneLab/` contains the debug-only developer UI for visually tuning DarkRoom Tonal Curve v1 constants against a real selected image.

## Depends On

- SwiftUI and AppKit for the debug window and clipboard export.
- `EditGraph/` for `EditRecipe`, `ToneTuning`, and overlay selection values.
- `Viewer/` and `ImagePipeline/` for the same color-managed preview path used by the normal app.
- `DesignSystem/` for existing control styling.

## Affords

- A separate developer window that can use the current selected image.
- Local, non-persisted normal light sliders for testing user-facing recipe values.
- Mutable hidden tuning constants that can be copied as JSON and later baked into the Rust-owned default tuning.
- Affected-range overlays for tonal controls using the same influence parameters as the renderer.

## Responsibilities

- Keep Tone Lab out of release UI surfaces.
- Keep tuning constants separate from user edit recipes and sidecar persistence.
- Favor fast visual iteration over polished end-user presentation.
- Route preview rendering through the existing viewer/image pipeline instead of inventing a second tone renderer.

## Boundaries

- Do not persist user recipes from this tool.
- Do not write candidate files until a real candidate-management workflow exists.
- Do not put portable tone math here; add math behavior to `darkroom_core` and bridge it through `EditGraph/`.
- Do not tune display profiles, preview target definitions, or RAW decode policy here.

## Update Triggers

Update when Tone Lab gains candidate storage, fixture workflows, graph diagnostics, or new tuning surfaces.
