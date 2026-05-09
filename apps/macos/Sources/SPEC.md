# macOS Sources Spec

## Purpose

`apps/macos/Sources/` holds Swift source for the native DarkRoom macOS app.

## Depends On

- SwiftUI for primary UI.
- AppKit where macOS-specific interactions are required.
- Source membership from `Project.swift`.

## Affords

- A buildable app shell organized by responsibility: app entry, design system, UI composition, file browser, color pipeline policy, edit graph state, image pipeline rendering, histogram analysis, export, RAW decoding, color-managed viewer, inspector, and settings.

## Responsibilities

- Keep view composition readable.
- Keep folder/file scanning and UI state in small models.
- Keep preview/output color target policy in `ColorPipeline/`.
- Keep non-destructive recipe state and sidecar persistence in `EditGraph/`.
- Keep shared source decode, edit application, proofing, and display conversion in `ImagePipeline/`.
- Keep edited-image histogram analysis and clipping state in `Histogram/`.
- Keep file writing and save-panel export flow in `Exporting/`.
- Keep RAW decoder swappability in `RawDecoding/`.
- Keep preview render-readiness in the viewer layer so inspector controls can reflect whether a trustworthy preview exists.
- Keep future engine bridge calls isolated from presentation views.
- Keep current Rust C ABI calls wrapped in feature/model layers, not presentation views.
- Route repeated visual decisions through `DesignSystem/` instead of duplicating local styling.

## Boundaries

- Do not let `View` structs become engine controllers.
- Do not place Metal shader code or Rust source here.
- Do not hard-code color-management policy directly inside feature views.
- Do not add app-wide globals for edit state when a model or engine boundary is clearer.
- Do not create design-system components for one-off UI unless the reuse or design-language value is clear.

## Update Triggers

Update when source folders are reorganized or new Swift ownership boundaries are introduced.
