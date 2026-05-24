# EditGraph Spec

## Purpose

`EditGraph/` owns the non-destructive edit recipe values used by preview and export.

## Depends On

- Foundation value types.
- SwiftUI only for lightweight bindings in the session model.
- The linked `darkroom_core` C ABI for V1 tonal parameter math.
- `docs/edit-graph.md` for operation ordering and persistence intent.

## Affords

- A V1 tone recipe: exposure, contrast, pivot, highlights, shadows, whites, and blacks.
- A V1 `ToneTuning` model for hidden developer constants that shape how visible tone sliders map into kernel behavior.
- A developer-only `BehaviorTuning` candidate model that wraps tone tuning, exposure feel, exposure-shadow range shaping, color coupling, per-slider mapping, view-transform notes, overlay tuning, and candidate metadata for Tone Lab export and preview.
- Rust-backed sampling helpers for Tone Lab diagnostics, including per-slider mapping response previews.
- Per-file edit state that loads from and saves to DarkRoom XMP sidecars beside source images.
- One value schema that inspector controls, preview rendering, and export rendering can share.

## Responsibilities

- Keep edit values independent from UI controls.
- Keep hidden tuning constants separate from user-facing recipes and sidecar persistence.
- Keep V1 slider ranges and neutral defaults centralized.
- Keep per-slider mapping, exposure-feel, exposure-shadow range, signed endpoint/range, curve-shaping, regional chroma mode, color-coupling, and overlay-tuning values in the hidden tuning layer and pass them through the Rust-backed parameter contract rather than hard-coding response curves in views.
- Keep the named V1 curve model beside the recipe values so future tone-curve versions can preserve old edits.
- Provide recipe lookup that caches current-session values immediately while coalescing sidecar writes off the live adjustment path.
- Keep sidecar persistence text-based, versioned, and owned by the recipe layer.

## Boundaries

- Do not decode images or render pixels here.
- Do not embed Core Image, Metal, or export implementation details here.
- Do not store library/catalog state here; this layer only owns per-source edit sidecars.
- Do not add Adobe-private develop settings unless we intentionally choose an interoperability contract.

## Update Triggers

Update when edit parameters, hidden behavior tuning, curve model names, default values, operation ordering, persistence ownership, or recipe versioning changes.
