# ColorPipeline Spec

## Purpose

`ColorPipeline/` owns V1 color-management policy shared by preview and future export paths.

## Depends On

- Core Graphics color-space APIs.
- `docs/color-pipeline.md` for product and technical intent.

## Affords

- Named preview targets that represent output conditions, not physical displays.
- A single working-space definition for the V1 edit pipeline.
- Small value types that can be passed into viewer, export, and test code without pulling UI state into color logic.

## Responsibilities

- Define V1 preview/output targets such as Web / Instagram and Apple Display P3.
- Define the V1 wide-gamut working color space.
- Keep user-facing labels and color profile identifiers centralized.
- Preserve the distinction between preview target, export profile, working space, and display profile.

## Boundaries

- Do not decode files here.
- Do not render SwiftUI/AppKit views here.
- Do not store user state here.
- Do not implement edit graph math here; color policy should stay separate from editing operations.

## Update Triggers

Update when preview targets, export targets, working-space policy, color profile names, or the preview/export parity contract changes.
