# Development Workflow

DarkRoom should be developed from Cursor or VS Code with terminal scripts as the stable interface.

## Normal Loop

```bash
./scripts/doctor.sh
./scripts/generate.sh
./scripts/dev.sh
```

During implementation:

```bash
./scripts/test-rust.sh
./scripts/test-swift.sh
./scripts/test.sh
```

Before committing:

```bash
./scripts/format.sh
./scripts/lint.sh
./scripts/test.sh
```

## Xcode Role

Xcode is a toolchain and specialist debugger, not the source of truth for project structure.

Use Xcode for:

- Metal frame capture.
- Instruments profiling.
- Signing and entitlement debugging.
- SwiftUI previews when useful.
- Crash/debug sessions that are easier in Xcode.

Do not manually restructure the project inside Xcode. Update source-controlled project config and run `./scripts/generate.sh`.

## Tooling Status

The preferred project generator is Tuist. XcodeGen is the fallback. If neither is installed, Rust tests and docs can still move forward, but the native app workspace cannot be generated yet.

Swift build/test scripts call `scripts/build-rust-core.sh` before invoking Xcode because the macOS app links the `darkroom_core` static library for V1 light-control math.

Scripts source `scripts/env.sh`, which points `DEVELOPER_DIR` at `/Applications/Xcode.app/Contents/Developer` when full Xcode is installed. To make that the machine-wide default outside this repo, run:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```
