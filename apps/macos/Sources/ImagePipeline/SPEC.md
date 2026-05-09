# ImagePipeline Spec

## Purpose

`ImagePipeline/` owns the shared source decode, edit application, output proofing, and display conversion used by viewer previews and exports.

## Depends On

- Core Image and Image I/O for V1 raster processing.
- `ColorPipeline/` for preview/export target profiles and working-space policy.
- `EditGraph/` for non-destructive recipe values and Rust-derived light parameters.
- `RawDecoding/` for RAW source interpretation.
- `LocalImageFile` for source file type policy.

## Affords

- One render path where preview and export share source interpretation, working color space, and edit math.
- A prepared-source path that lets the viewer reuse the current decode while applying new edit recipes.
- Reusable Core Image render contexts so interactive preview updates do not rebuild heavyweight context state for every frame.
- Display preview rendering that ends at the current Mac display profile.
- Export rendering that ends at the requested output profile without using cached viewer pixels.

## Responsibilities

- Decode raster and RAW inputs into Core Image sources.
- Expose source preparation separately from display rendering so interactive preview updates do not reload the same source for every slider tick.
- Support bounded preview source and output sizes for live viewing while preserving full-resolution source-plus-recipe export.
- Apply V1 light adjustments in the shared pipeline using parameters supplied by the Rust-owned recipe math.
- Preserve tone ordering for shadow/highlight recovery; these controls should reshape luminance with bounded toe/shoulder behavior rather than invert or cross tonal regions.
- Convert edited output through Linear ROMM RGB into selected preview/export targets.
- Keep display profile conversion as a preview-only final stage.

## Boundaries

- Do not present UI, panels, alerts, or toolbar behavior here.
- Do not write files here; export file writing belongs in `Exporting/`.
- Do not own edit state or persistence.
- Do not define design-system controls.

## Update Triggers

Update when decode strategy, edit math placement, Rust bridge usage, preview/export parity rules, or pipeline ownership changes.
