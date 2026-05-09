# ADR 0001: Native macOS, Cursor-first Workflow

## Status

Accepted

## Context

DarkRoom needs native-feeling macOS performance, local file access, color-managed viewing, Metal rendering, scopes, and pro creative-tool UX. The project also needs an AI-assisted workflow centered around Cursor or VS Code rather than manual Xcode operation.

## Decision

Build a native macOS app using SwiftUI/AppKit and Apple imaging frameworks, backed by a Rust core. Use generated project tooling and scripts so development happens primarily through Cursor and Terminal. Keep Xcode installed but not central.

## Consequences

Positive:

- Best chance of native performance and pro macOS feel.
- Cursor remains the daily workspace.
- Terminal scripts make agentic development possible.
- Rust core keeps long-term portability alive.

Negative:

- More setup complexity than a pure web or Tauri app.
- Some Apple-specific debugging still requires Xcode or Instruments.
- Swift/Rust interop adds architectural overhead.

## Rule

Any required development task must have a documented script or command.
