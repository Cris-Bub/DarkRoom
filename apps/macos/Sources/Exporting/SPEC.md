# Exporting Spec

## Purpose

`Exporting/` owns user-initiated file export for edited images.

## Depends On

- AppKit save panels for macOS destination selection.
- Image I/O for writing image files and embedding profiles.
- `ImagePipeline/` for source decode, edit application, and output-profile rendering.
- `ColorPipeline/` for V1 export targets.
- `EditGraph/` for non-destructive edit recipes.

## Affords

- JPEG, PNG, and TIFF export from the selected source image.
- Output-profile-aware rendering for Web / Instagram sRGB and Apple Display P3.
- ICC-tagged output files that are rendered from source plus recipe, never from cached viewer pixels.

## Responsibilities

- Ask the user where to write an export.
- Re-render the selected source with the current edit recipe for the selected output target.
- Embed the selected output profile in the exported image.
- Surface export progress and failures to UI code.

## Boundaries

- Do not store edit values here.
- Do not own viewer preview state.
- Do not bypass `ImagePipeline/` for pixel rendering.
- Do not add batch export, presets, resizing, sharpening, watermarking, or metadata policy until they are designed.

## Update Triggers

Update when export formats, output profile policy, metadata embedding, batch behavior, or save-panel ownership changes.
