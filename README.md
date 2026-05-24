# DarkRoom

DarkRoom is the start of a local-first, open-source macOS photo grading workstation. The goal is a native app that opens folders directly, keeps originals untouched, and gives photographers colorist-grade controls without forcing a catalog, cloud account, or web app shell.

The product direction is deliberately closer to a still-image grading room than a generic editor: fast folder browsing, a calm native interface, non-destructive recipes, color-managed viewing, scopes, masks, and a portable Rust engine for the math that needs to stay testable.

## Current State

DarkRoom now has the early V1 shell plus the first color-managed edit/export path:

- Native SwiftUI/AppKit macOS shell source under `apps/macos`
- Rust workspace with a first `darkroom_core` crate under `crates`
- Local image browsing, color-managed viewing, and persisted light edits
- A seven-control V1 tonal model with Exposure, Contrast, Pivot, Highlights, Shadows, Whites, and Blacks
- Live DarkRoom XMP sidecars for non-neutral edit recipes
- JPEG, PNG, and TIFF export rendered from source plus recipe
- Cursor-first script entrypoints under `scripts`
- Architecture, workflow, design system, color, edit graph, masking, and scopes docs under `docs`
- Agent operating rules in `Agent.md`
- Boundary specs in `SPEC.md` files so future agents know what each area owns

## Quickstart

```bash
./scripts/doctor.sh
./scripts/test-rust.sh
```

If you prefer shorter command names, the repo also includes `make` aliases for the same scripts:

```bash
make doctor
make test-rust
```

To build and run the macOS app once Tuist or XcodeGen is installed:

```bash
./scripts/generate.sh
./scripts/dev.sh
```

Or with the `make` aliases:

```bash
make generate
make dev
```

Daily development should happen in Cursor or VS Code. Xcode is still required as the Apple toolchain for SDKs, signing, Instruments, Metal tooling, and occasional debugging, but project structure should live in source-controlled files and scripts.

## Project Shape

```txt
apps/macos/       Native macOS app shell, views, file browser, viewer, inspector.
crates/           Portable Rust engine code, math, schemas, and future FFI.
docs/             Architecture notes, workflow docs, decisions, and subsystem specs.
fixtures/         Offline test images, LUTs, and golden outputs.
scripts/          Stable terminal interface for setup, build, run, test, format.
shaders/metal/    Future Metal shader entrypoints for viewer, scopes, masks, color ops.
```

## Product Principles

- Local-first: the app must work without a backend, cloud account, or import step.
- Non-destructive: edits are recipes; originals are never rewritten by editing.
- Native macOS: SwiftUI/AppKit for the shell, Metal/Core Image/Image I/O/ColorSync at platform boundaries.
- Portable engine: Rust owns color math, edit graph rules, cache/index logic, masks, presets, and tests.
- Agent-friendly: every required development task gets a documented terminal command.
- Design-system aware: repeated UI decisions should flow through documented tokens and reusable SwiftUI components.
- Responsibility boundaries matter: no engine math in SwiftUI views, no macOS-only UI concerns in portable Rust crates.

## Design System

DarkRoom tracks UI decisions in [docs/design-system.md](docs/design-system.md). The app follows an atomic design convention:

- Tokens: spacing, typography, icon roles, and future color/radius/motion roles.
- Atoms: small reusable UI elements.
- Molecules: reusable control groups.
- Organisms: feature sections such as sidebar, viewer, inspector, and future scopes.
- Templates/scenes: window-level structure.

SwiftUI design-system code lives under `apps/macos/Sources/DesignSystem`. Prefer native macOS controls first, and promote a component only when reuse or consistency value is real.

## Early Milestones

### Milestone 0: Native Shell And Workflow Proof

- Generate a native macOS project from source-controlled config.
- Build and launch a three-panel app shell.
- Open a local folder through the system picker.
- List supported image files.
- Display the selected image in the viewer.
- Toggle the viewer background.
- Keep Rust tests passing.

### Milestone 1: Non-Destructive Edit Graph Prototype

- Add exposure, contrast, pivot, highlights, shadows, whites, and blacks controls.
- Store edits as non-destructive recipe data.
- Persist non-neutral edits into sidecars beside source images.
- Keep originals untouched.
- Export from source plus recipe.
- Persist edit state.
- Add CPU reference tests for core math.

### Milestone 2: Color-Managed Viewer And Scopes Foundation

- Add an ICC-aware display path.
- Read embedded image profiles where available.
- Add histogram and waveform or RGB parade prototypes.
- Persist viewer background preference.

## License

DarkRoom is released under the MIT License. See `LICENSE`.
