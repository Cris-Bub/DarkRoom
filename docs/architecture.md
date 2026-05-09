# Architecture

DarkRoom is a native macOS app with a portable engine core.

## Layers

### macOS Shell

The SwiftUI/AppKit shell owns:

- Window and toolbar behavior.
- Folder picker and future security-scoped bookmark handling.
- Sidebar, viewer, inspector, settings, and native UI state.
- Platform display integration through Apple frameworks.

The shell should remain thin. It can coordinate user intent and display state, but it should not own grading math or portable edit schema behavior.

### Rust Engine

Rust owns the testable and portable parts:

- Edit recipes and future edit graph ordering.
- Exposure, contrast, curve, color, mask, and scope math.
- Cache/index rules.
- Preset and sidecar schemas.
- CPU reference implementations used to validate GPU behavior.

The first crate is `darkroom_core`, which currently provides reference light-control math and a small C ABI used by the macOS target for V1 light parameter mapping.

### Platform Imaging

The intended platform layer uses:

- Image I/O for common still image decode and metadata.
- Core Image for selected Apple imaging integrations and RAW intake.
- ColorSync for display profile awareness.
- Metal for viewer, scopes, masks, and performance-critical rendering.

The long-term renderer should be owned by the app instead of being a loose pile of generic filters.

### Generated Project

`Project.swift` is the source-controlled Tuist project definition. Generated Xcode files are build artifacts and should not be edited manually.

## Boundary Rule

When a change makes a layer know more about another layer, update the relevant `SPEC.md` and consider whether the dependency belongs there at all.
