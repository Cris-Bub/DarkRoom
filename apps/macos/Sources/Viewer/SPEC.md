# Viewer Spec

## Purpose

`Viewer/` owns the macOS preview surface and the render-readiness state for the currently selected local image.

## Depends On

- SwiftUI and AppKit for the visible viewer and window/display integration.
- Image I/O and Core Image for first-pass preview rendering.
- `ColorPipeline/` for preview target and working-space policy.
- `RawDecoding/` for swappable RAW decoder behavior.
- `LocalImageFile` for supported file type and RAW-extension policy.
- Design-system atoms for empty/loading/error presentation.

## Affords

- A viewer pane that displays the selected file against the chosen background.
- A render model that reports whether the selected image has decoded into the current display preview.
- A display-profile-aware preview cache that can be invalidated when the window moves between screens or the backing color space changes.

## Responsibilities

- Decode the selected file into a preview-target-proofed, display-referred preview image.
- Keep render status separate from inspector/edit state so controls can become read-only while no trustworthy preview exists.
- Re-render previews when the selected file, selected preview target, or window display color profile changes.
- Preserve source, working, preview target, and display color profile intent in documentation and code.

## Boundaries

- Do not put non-destructive edit graph math here.
- Do not own preview target definitions or working color-space policy.
- Do not own RAW decoder implementations.
- Do not treat the viewer preview cache as export-ready image data.
- Do not hide RAW rendering failures behind unrelated UI state.
- Do not add permanent cache/index behavior here; that belongs in a future cache subsystem or engine layer.

## Update Triggers

Update when preview decode strategy, color-space policy, display-profile observation, render status semantics, or viewer ownership changes.
