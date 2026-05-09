# Viewer Spec

## Purpose

`Viewer/` owns the macOS preview surface and the render-readiness state for the currently selected local image.

## Depends On

- SwiftUI, AppKit, and MetalKit for the visible viewer and window/display integration.
- `ColorPipeline/` for preview target and working-space policy.
- `ImagePipeline/` for shared decode, edit application, proofing, and display conversion.
- `EditGraph/` for recipe identity when deciding whether the preview matches current edits.
- `RawDecoding/` for swappable RAW decoder behavior.
- Design-system atoms for empty/loading/error presentation.

## Affords

- A viewer pane that displays the selected file against the chosen background.
- A Metal-backed live preview surface that applies the current edit recipe directly into the viewer drawable.
- A render model that reports whether the selected image has decoded into the current display preview.
- A displayable previous preview during same-file edit rerenders so light-control drags do not blank the image between frames.
- A latest-request-wins render scheduler for interactive control drags so stale slider positions do not queue up behind the current frame.
- A display-profile-aware preview cache that can be invalidated when the window moves between screens or the backing color space changes.

## Responsibilities

- Use the Metal-backed viewer for interactive display updates instead of swapping AppKit images during slider drags.
- Ask `ImagePipeline/` to render the selected file into a preview-target-proofed, display-referred preview image when model readiness or non-interactive fallback data is needed.
- Pass the viewer's current pixel size to preview rendering so interactive frames are rendered for the display surface, not full-resolution export dimensions.
- Drop to a lower-resolution bounded preview while an adjustment slider is actively dragging, then request a normal viewer-resolution frame when the drag ends.
- Keep render status separate from inspector/edit state so controls can become read-only while no trustworthy preview exists.
- Keep displayability separate from exact-recipe readiness: a stale same-file preview may remain visible while the next recipe renders, but it must not be reported as ready for that recipe.
- Reuse the prepared source for the current selected file while edit recipes change, without turning viewer pixels into export input.
- Re-render previews when the selected file, edit recipe, selected preview target, or window display color profile changes.
- Preserve source, working, preview target, and display color profile intent in documentation and code.

## Boundaries

- Do not put non-destructive edit graph math here.
- Do not decode source files here now that `ImagePipeline/` owns that shared path.
- Do not own preview target definitions or working color-space policy.
- Do not own RAW decoder implementations.
- Do not treat the viewer preview cache as export-ready image data.
- Do not hide RAW rendering failures behind unrelated UI state.
- Do not add permanent cache/index behavior here; that belongs in a future cache subsystem or engine layer.

## Update Triggers

Update when preview decode strategy, color-space policy, display-profile observation, render status semantics, or viewer ownership changes.
