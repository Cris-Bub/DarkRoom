# Edit Graph

DarkRoom edits are recipes, not rewritten pixels.

## Purpose

The edit graph defines operation ordering, parameter schema, persistence, presets, and future mask attachment semantics.

## MVP Direction

Milestone 1 should add a minimal recipe with:

- Exposure.
- Contrast.
- Contrast pivot.
- Master curve placeholder.

The original file must remain untouched. Export is where pixels become final output for other apps.

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

Use SQLite for local indexing and cache registry. Use XMP for interoperable metadata. Use app-native versioned sidecars for full-fidelity edit graph state until the schema stabilizes.
