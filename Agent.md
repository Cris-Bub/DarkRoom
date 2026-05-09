# Agent Operating Rules

This repository is built to stay understandable to AI agents and human maintainers over a long timeline. Before changing a subsystem, read the nearest `SPEC.md` and any linked docs so the change lands in the right layer.

## Always Check First

1. Read `README.md` for the current project direction.
2. Read the closest `SPEC.md` for the folder or file area you are touching.
3. Read the relevant subsystem doc in `docs/` for architecture, workflow, design system, color, edit graph, masks, or scopes.
4. If a change crosses a boundary, treat that with caution and verify it is necessary before updating both sides' specs or explaining why the boundary remains unchanged.

## Spec Doc Convention

Every meaningful folder should have a `SPEC.md` before or alongside implementation. Important root files are documented in `docs/specs/root-files.md`.

Each spec should answer:

- Purpose: what this file or folder is for.
- Depends on: what it is allowed to import, call, or assume.
- Affords: what other code can rely on it to provide.
- Responsibilities: what belongs here.
- Boundaries: what must not be added here.
- Update triggers: what kinds of changes require this spec to be revised.

Do not create specs for generated artifacts, transient build output, or trivial leaf files unless they become a source of architectural confusion.

## Architecture Rules

- SwiftUI/AppKit owns macOS UX, window behavior, folder pickers, and native platform integration.
- Rust owns portable edit recipes, graph evaluation rules, color math, mask math, cache/index logic, presets, and tests.
- Metal shaders own GPU kernels only; algorithm intent belongs in Rust docs and tests where practical.
- Keep UI state separate from engine state. Views should bind to models rather than containing grading math.
- Keep platform-specific macOS code out of portable Rust crates unless it is intentionally isolated behind an FFI boundary.
- Never change image math casually. Add or update tests and document behavior changes in `docs/decisions/`.

## UI And Design System Rules

- Read `docs/design-system.md` before substantial UI changes.
- Prefer existing design tokens and reusable SwiftUI components from `apps/macos/Sources/DesignSystem`.
- Follow the atomic design convention: tokens, atoms, molecules, organisms, templates, scenes.
- Use native macOS controls unless the design system documents a product-specific wrapper.
- Promote UI into the design system only when it has real reuse, consistency, or future-change value.
- Keep design-system components presentational; feature state belongs in feature modules.
- When adding or changing a token/component, update `docs/design-system.md` and the nearest `SPEC.md`.

## Development Commands

Use scripts instead of hidden IDE steps:

```bash
./scripts/doctor.sh
./scripts/generate.sh
./scripts/dev.sh
./scripts/test.sh
./scripts/test-rust.sh
./scripts/test-swift.sh
./scripts/format.sh
./scripts/lint.sh
```

If a task is required to develop the app and no script exists, add or document one.

## Generated Files

Do not manually edit generated Xcode project or workspace files. Update `Project.swift`, package config, source files, or scripts, then run `./scripts/generate.sh`.

## Documentation Duty

When adding a meaningful folder, subsystem, file format, or cross-module dependency, add or update the relevant spec before finishing. The point is to preserve intent, dependencies, affordances, and boundaries so future agents do not mix responsibilities or inflate the codebase.
