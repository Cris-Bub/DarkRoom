# Edit Graph

DarkRoom edits are recipes, not rewritten pixels.

## Purpose

The edit graph defines operation ordering, parameter schema, persistence, presets, and future mask attachment semantics.

## V1 Direction

V1 now has a recipe model in `apps/macos/Sources/EditGraph` with:

- Exposure.
- Contrast.
- Contrast pivot.
- Highlights.
- Shadows.
- Whites.
- Blacks.
- A named `darkroom_tonal_curve_v1` curve model.

The original file must remain untouched. Export is where pixels become final output for other apps. The current recipe store caches values in memory during the app session and persists non-neutral values to a sidecar next to the source image without blocking live adjustments.

## V1 Sidecar Persistence

DarkRoom now writes a small XMP sidecar beside each edited source image. The V1 filename is `source-file.ext.xmp`, which avoids collisions when a RAW and rendered file share the same basename. The sidecar uses standard XMP/RDF packet structure with a DarkRoom-owned namespace for the current edit recipe values.

Neutral recipes remove the sidecar. Non-neutral recipe changes update the in-memory session state immediately, then sidecar writes are coalesced off the main thread and flushed at the end of an adjustment drag so the source image stays untouched while edits survive app relaunches.

V1 sidecars are not Adobe Camera Raw compatibility files. They are intentionally DarkRoom-owned recipe files with room to add interoperable metadata later. Current sidecars store the tone curve model name beside the visible slider values so future curve versions can avoid silently changing old edits. Older V1 sidecars without Pivot, Whites, Blacks, or ToneCurveModel load with those new values at neutral.

## Ordering Sketch

The current V1 tone order is:

1. Decode and normalize.
2. Technical corrections and white balance.
3. Exposure as a real scene-linear EV multiplier.
4. Highlights and shadows as broad log-luminance zone redistribution.
5. Whites and blacks as endpoint energy/density shaping.
6. Contrast and pivot as one smooth middle-gray anchored curve.
7. Future curves.
8. Color controls and hue curves.
9. Local masks and qualified corrections.
10. Effects.
11. Display transform and scopes.

## Persistence Direction

Use SQLite for local indexing and cache registry. Use XMP for interoperable metadata and current simple sidecars. Use app-native versioned sidecars for full-fidelity edit graph state if XMP attributes become too cramped for the complete graph.

## V1 Tonal Math

- Exposure is stored as EV and mapped to `2^EV`.
- Core tone changes compute working-space luminance, map luminance in log2 stops around middle gray, then apply a hue-preserving luminance gain back to RGB.
- Contrast is stored as a `-100...100` slider and mapped through a nonlinear signed strength. Pivot is stored as `-2...2` EV relative to middle gray and is part of the same curve, not a separate brightness operation.
- Highlights, shadows, whites, and blacks are stored as `-100...100` sliders and mapped through nonlinear, bounded EV adjustments. Highlights and shadows target broad bright/dark tonal zones; whites and blacks target endpoint energy/density.
- The named `darkroom_tonal_curve_v1` remains monotonic under slider extremes so the tone curve cannot visually flip from bottom-left/top-right into a reversed curve.
- Rust owns the scalar reference math, tone-shaping constants, and V1 kernel-parameter mapping. The Swift image pipeline applies those Rust-derived parameters through a Core Image path so preview and export match. Rust remains the intended long-term owner for more of the portable edit graph and reference math.
