# EditGraph Spec

## Purpose

`EditGraph/` owns the non-destructive edit recipe values used by preview and export.

## Depends On

- Foundation value types.
- SwiftUI only for lightweight bindings in the session model.
- The linked `darkroom_core` C ABI for V1 light-control parameter math.
- `docs/edit-graph.md` for operation ordering and persistence intent.

## Affords

- A small V1 light recipe: exposure, contrast, highlights, and shadows.
- Per-file edit state that loads from and saves to DarkRoom XMP sidecars beside source images.
- One value schema that inspector controls, preview rendering, and export rendering can share.

## Responsibilities

- Keep edit values independent from UI controls.
- Keep V1 slider ranges and neutral defaults centralized.
- Provide recipe lookup that caches current-session values immediately while coalescing sidecar writes off the live adjustment path.
- Keep sidecar persistence text-based, versioned, and owned by the recipe layer.

## Boundaries

- Do not decode images or render pixels here.
- Do not embed Core Image, Metal, or export implementation details here.
- Do not store library/catalog state here; this layer only owns per-source edit sidecars.
- Do not add Adobe-private develop settings unless we intentionally choose an interoperability contract.

## Update Triggers

Update when edit parameters, default values, operation ordering, persistence ownership, or recipe versioning changes.
