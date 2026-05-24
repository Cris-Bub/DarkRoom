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
- A developer-only Exposure Feel curve editor for deciding which scene stops receive extra positive-exposure shadow visibility while the real EV gain remains stop-linear.
- Developer-only visual influence curve editors for Highlights, Shadows, Whites, and Blacks so the founding colorist can taste signed luminance range, body bias, peak damping, and strength by eye.
- A Rust-backed per-slider response graph that shows default versus candidate mapping, dead zone, soft limit, and the current test-slider position.
- Developer-facing help popover icons for dense slider and chroma-mode controls.
- Affected-range and diagnostic overlays for tonal controls using the same renderer influence, color-coupling, and overlay tuning parameters as preview.
- Section-level resets for test recipe values and each hidden tuning group, plus per-slider resets for returning one numeric tuning value to its default without disturbing nearby controls.
- Color protection controls that use the reset/default value as the neutral center, so dragging above default damps chroma movement and dragging below default loosens it for visual exploration.
- Solo and sweep controls for judging each visible slider from subtle to extreme settings.

## Responsibilities

- Keep Tone Lab out of release UI surfaces.
- Keep tuning constants separate from user edit recipes and sidecar persistence.
- Favor fast visual iteration over polished end-user presentation.
- Route preview rendering through the existing viewer/image pipeline instead of inventing a second tone renderer.
- Keep section resets local to the visible Tone Lab group instead of changing unrelated tuning constants.
- Keep per-slider resets tied to the exact production default value for that field, not the midpoint of the control range.
- Keep help text explicit about directional controls whose reset/default value is the neutral center rather than the minimum.
- Keep response graphs sampled through the `EditGraph/` Rust bridge so Tone Lab diagnostics match the renderer mapping contract.
- Keep per-slider mapping, exposure feel, exposure-shadow range shaping, signed endpoint/range, curve shape, regional chroma mode, color-coupling, and overlay experiments wired through `BehaviorTuning` so Rust remains the source of truth for mapping visible slider values into renderer parameters.

## Boundaries

- Do not persist user recipes from this tool.
- Do not write candidate files until a real candidate-management workflow exists.
- Do not put portable tone math here; add math behavior to `darkroom_core` and bridge it through `EditGraph/`.
- Do not tune display profiles, preview target definitions, or RAW decode policy here.

## Update Triggers

Update when Tone Lab gains candidate storage, fixture workflows, graph diagnostics, new tuning surfaces, or changes to exported behavior JSON.
