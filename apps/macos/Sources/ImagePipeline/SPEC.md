# ImagePipeline Spec

## Purpose

`ImagePipeline/` owns the shared source decode, edit application, output proofing, and display conversion used by viewer previews, histogram analysis, and exports.

## Depends On

- Core Image and Image I/O for V1 raster processing.
- `ColorPipeline/` for preview/export target profiles and working-space policy.
- `EditGraph/` for non-destructive recipe values, hidden tone tuning values, and Rust-derived tonal parameters.
- `RawDecoding/` for RAW source interpretation.
- `LocalImageFile` for source file type policy.

## Affords

- One render path where preview and export share source interpretation, working color space, and edit math.
- A prepared-source path that lets the viewer reuse the current decode while applying new edit recipes.
- Reusable Core Image render contexts so interactive preview updates do not rebuild heavyweight context state for every frame.
- Display preview rendering that ends at the current Mac display profile.
- Histogram preview rendering that ends at the selected preview target without display-profile conversion.
- Export rendering that ends at the requested output profile without using cached viewer pixels.

## Responsibilities

- Decode raster and RAW inputs into Core Image sources.
- Expose source preparation separately from display rendering so interactive preview updates do not reload the same source for every slider tick.
- Support bounded preview source and output sizes for live viewing while preserving full-resolution source-plus-recipe export.
- Support bounded histogram renders from source plus recipe so analysis does not sample viewer pixels.
- Apply V1 tonal adjustments in the shared pipeline using parameters supplied by the Rust-owned recipe and tuning math.
- Preserve tone ordering for the DarkRoom Tonal Curve v1; global tonal controls should reshape luminance with bounded toe/shoulder behavior rather than invert or cross tonal regions.
- Convert edited output through Linear ROMM RGB into selected preview/export targets.
- Keep display profile conversion as a preview-only final stage.

## Boundaries

- Do not present UI, panels, alerts, or toolbar behavior here.
- Do not write files here; export file writing belongs in `Exporting/`.
- Do not own edit state or persistence.
- Do not convert histogram analysis into a viewer-readiness or export-writing workflow.
- Do not define design-system controls.

## Update Triggers

Update when decode strategy, edit math placement, tonal curve behavior, Rust bridge usage, preview/export parity rules, or pipeline ownership changes.
