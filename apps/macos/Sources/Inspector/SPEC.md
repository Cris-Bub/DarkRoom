# Inspector Spec

## Purpose

`Inspector/` owns the right-side editing inspector surface for the main DarkRoom window.

## Depends On

- SwiftUI for native inspector composition.
- `DesignSystem/` atoms and molecules for reusable DarkRoom controls.
- `EditGraph/` for non-destructive edit recipe bindings.
- `ColorPipeline/`, `Settings/`, and `Histogram/` for preview target, viewer background, and histogram state.

## Affords

- The main edit inspector page, mode rail, image details panel, histogram placement, and editing sections.
- Bindings for viewer proofing, viewer background, and V1 light edit values.
- Section-level reset affordances for stateful inspector groups.

## Responsibilities

- Keep inspector controls bound to app models and feature callbacks.
- Keep read-only preview readiness visible without changing layout.
- Keep section resets scoped to the section state they represent.
- Use design-system components for repeated inspector interaction patterns.

## Boundaries

- Do not decode images, render pixels, write sidecars directly, or own portable edit math here.
- Do not add custom control styling that belongs in `DesignSystem/`.
- Do not persist viewer or edit state outside the app models and bindings provided by parent views.

## Update Triggers

Update when inspector sections, mode behavior, reset behavior, state ownership, or cross-module dependencies change.
