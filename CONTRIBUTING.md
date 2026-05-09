# Contributing

DarkRoom is early-stage. The most valuable contributions right now are small, well-scoped changes that preserve module boundaries and improve the build, test, and documentation loop.

## Development Loop

```bash
./scripts/doctor.sh
./scripts/test-rust.sh
./scripts/generate.sh
./scripts/dev.sh
```

Run the narrowest relevant checks while iterating. Before opening a pull request, run:

```bash
./scripts/format.sh
./scripts/lint.sh
./scripts/test.sh
```

## Documentation Expectations

Every meaningful subsystem should have a nearby `SPEC.md`. If your change adds a responsibility, dependency, or public affordance, update the spec in the same change.

Architecture decisions that affect color math, edit graph ordering, persistence, file access, project generation, or rendering belong in `docs/decisions/`.

## Boundaries

- SwiftUI/AppKit code should not own grading math.
- Rust engine code should not assume macOS UI behavior.
- Generated Xcode files should not be edited manually.
- Test fixtures must work offline.
