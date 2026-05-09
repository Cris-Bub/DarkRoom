# Edit Graph

DarkRoom edits are recipes, not rewritten pixels.

## Purpose

The edit graph defines operation ordering, parameter schema, persistence, presets, and future mask attachment semantics.

## V1 Direction

V1 now has a recipe model in `apps/macos/Sources/EditGraph` with:

- Exposure.
- Contrast.
- Highlights.
- Shadows.
- A fixed initial contrast pivot.

The original file must remain untouched. Export is where pixels become final output for other apps. The current recipe store caches values in memory during the app session and persists non-neutral values to a sidecar next to the source image without blocking live adjustments.

## V1 Sidecar Persistence

DarkRoom now writes a small XMP sidecar beside each edited source image. The V1 filename is `source-file.ext.xmp`, which avoids collisions when a RAW and rendered file share the same basename. The sidecar uses standard XMP/RDF packet structure with a DarkRoom-owned namespace for the current edit recipe values.

Neutral recipes remove the sidecar. Non-neutral recipe changes update the in-memory session state immediately, then sidecar writes are coalesced off the main thread and flushed at the end of an adjustment drag so the source image stays untouched while edits survive app relaunches.

V1 sidecars are not Adobe Camera Raw compatibility files. They are intentionally DarkRoom-owned recipe files with room to add interoperable metadata later.

## Ordering Sketch

The exact order remains open, but the early light module should be isolated enough to test independently:

1. Decode and normalize.
2. Technical corrections and white balance.
3. Light controls.
4. Curves.
5. Color controls and hue curves.
6. Local masks and qualified corrections.
7. Effects.
8. Display transform and scopes.

## Persistence Direction

Use SQLite for local indexing and cache registry. Use XMP for interoperable metadata and current simple sidecars. Use app-native versioned sidecars for full-fidelity edit graph state if XMP attributes become too cramped for the complete graph.

## V1 Light Math

- Exposure is stored as EV and mapped to `2^EV`.
- Contrast is stored as a `-100...100` slider and mapped to a pivoted exponent around middle gray.
- Highlights and shadows are stored as `-100...100` sliders and normalized to `-1...1`, but they are not raw gain buckets.
- Shadows use a toe-style luminance shaper: positive values lift dark tones toward middle gray with black anchored; negative values darken shadows with a bounded floor instead of multiplying them into nothing.
- Highlights use a shoulder-style luminance shaper: negative values pull bright tones toward the shoulder without crossing middle gray; positive values brighten highlights while limiting clipping pressure.
- The V1 shadow/highlight curve must remain monotonic under extreme settings so the tone curve cannot visually flip from bottom-left/top-right into a reversed curve.
- Rust owns the scalar reference math, tone-shaping constants, and V1 kernel-parameter mapping. The Swift image pipeline applies those Rust-derived parameters through a Core Image path so preview and export match. Rust remains the intended long-term owner for more of the portable edit graph and reference math.
