# macOS App Spec

## Purpose

`apps/macos/` contains the native macOS shell for DarkRoom.

## Depends On

- SwiftUI and selective AppKit interop.
- Apple platform imaging frameworks at integration boundaries.
- Future Swift/Rust bridge code.
- `Project.swift` for generated project membership.

## Affords

- A native three-panel photo workstation shell.
- Local folder and image-file picking with supported still-image browsing.
- Viewer and inspector UI surfaces for future grading controls.

## Responsibilities

- macOS window, toolbar, file picker, sidebar, viewer, inspector, and settings UI.
- Local folder/image access flow and future security-scoped bookmark persistence.
- Displaying selected images before the full color-managed render path exists.

## Boundaries

- Do not implement portable color math in SwiftUI views.
- Do not persist final edit graph schema only in Swift UI models.
- Do not treat generated Xcode files as source.

## Update Triggers

Update when macOS target structure, UI ownership, folder access behavior, or bridge expectations change.
