# Histogram Spec

## Purpose

`Histogram/` owns image histogram analysis for the macOS inspector.

## Depends On

- SwiftUI observation for histogram model state.
- Core Graphics for pixel sampling.
- Rust `darkroom_core` C ABI for 256-bin RGBA histogram counting and per-pixel light recipe application during interactive previews.
- `ImagePipeline/` for source decode, edit application, and output-target proofing.
- `ColorPipeline/` for preview target policy.
- `EditGraph/` for current recipe values.
- `LocalImageFile` for selected source identity.

## Affords

- RGB and luminance histogram data for the currently selected edited image.
- Shadow and highlight clipping indicators derived from a bounded output-target render.
- Latest-request-wins scheduling so slider changes do not queue stale histogram work.
- A cached neutral RGBA8 analysis buffer per file/preview-target so interactive slider edits skip the full Core Image pipeline.
- A Rust fast path that applies the V1 light recipe and bins in one C ABI call during slider drags, with a normal settled pipeline pass when dragging ends.
- An inspector view that draws a per-bin gray-or-muted-blend body for overlapping channels and reserves pure channel color for thin top outlines.

## Responsibilities

- Render a small analysis image from source plus recipe through the shared image pipeline.
- Cache a neutral analysis buffer once per file/preview-target/raw-baseline so slider drags do not re-run the Core Image proof step.
- Convert sampled pixels into deterministic 256-bin RGB/luminance counts through the Rust-backed binning helper, optionally applying the current light recipe in the same Rust call.
- Keep histogram calculation and scheduling out of SwiftUI views.
- Treat the fast interactive pass as an approximation of the canonical pipeline; rely on the settled pass for accurate histogram output once the slider stops.

## Boundaries

- Do not own edit recipe persistence.
- Do not implement independent color or light adjustment math.
- Do not read viewer pixels or cached export output as histogram input.
- Do not present controls beyond histogram analysis state.

## Update Triggers

Update when histogram sampling, clipping policy, render stage, or scheduler ownership changes.
