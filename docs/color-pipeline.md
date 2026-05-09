# Color Pipeline

DarkRoom should be scene-referred and wide-gamut internally, with output proofing and display rendering handled as separate stages.

## Starting Position

The first implemented code is CPU reference math for exposure and pivoted contrast in `darkroom_core`. These functions are intentionally simple and testable. They establish the pattern for future color work: define behavior, write a CPU reference, then allow GPU paths to match it.

## Intended Pipeline

1. Decode image and metadata through Image I/O or a RAW backend.
2. Normalize into a scene-referred working representation.
3. Apply non-destructive edit recipe operations.
4. Convert through the selected preview/export target.
5. Render viewer output through the current monitor profile or embed the export profile in a file.
6. Generate scopes from defined pipeline taps, not arbitrary UI pixels.

## V1 Preview Targets

The viewer has a `View As` control with two V1 output-proof targets:

- `Web / Instagram`: sRGB output proof. This is the default because it matches normal web, social, and general client delivery expectations.
- `Apple Display P3`: Display P3 output proof for Apple-device and wide-gamut delivery expectations.

Preview targets are not display profiles. A preview target describes the output condition being simulated. The current display profile describes how the physical Mac display must be driven to show that output condition correctly.

## Viewer Accuracy Baseline

The first viewer implementation now has an explicit preview render boundary instead of relying on `NSImage(contentsOf:)`.

- RAW files are routed through the `RawDecoder` protocol. V1 ships `AppleRawDecoder`, backed by Apple's `CIRAWFilter`, with draft mode off, lens correction enabled when supported, gamut mapping enabled, and extended dynamic range output disabled for the current SDR viewer baseline.
- Raster files are decoded through Image I/O, preserving source color tags where available and treating untagged raster input as sRGB.
- Core Image renders through Linear ROMM RGB, then proof-converts to the selected preview target, then display-converts to the current window/display color space.
- The viewer observes window display/backing color-space changes and invalidates the preview cache when the app moves between displays or the display profile changes.
- The rendered viewer image is display-referred preview data only. It must not become the export source or the persistent edit representation.

This is display-management accuracy, not Lightroom visual matching. Lightroom/Camera Raw apply Adobe RAW profiles, defaults, sharpening, denoise, highlight behavior, and tone curves before the user moves a slider. DarkRoom needs its own declared RAW baseline first, then later camera/profile options if we want Adobe-like, camera-matching, or filmic starting points.

## Early Rules

- Exposure is a scene-linear stop control: `output = input * 2^EV`.
- Contrast is pivoted around middle gray, initially `0.18`.
- Display transforms are separate from edit operations.
- RAW white balance should eventually happen at RAW stage when RAW data is available.
- Viewer readiness should gate edit controls; users should not be able to move grading controls when the selected image has not decoded into the current display preview.
- Export must re-render from source plus edit recipe. It must not write cached viewer pixels.
- Exports must embed their output profile; silent untagged export is a bug.

## Open Decisions

- Whether Linear ROMM RGB remains the long-term working space once the Rust/Metal graph owns more of the pipeline.
- OpenColorIO dependency strategy.
- LibRaw integration timing and how much metadata should be common across Apple RAW and LibRaw.
- Whether the default RAW tone baseline should be Apple RAW defaults, a neutral scene-linear profile, camera-matching profiles, or a DarkRoom-authored look.
- EDR/HDR viewer mode policy for XDR-capable displays.
- How film density and grain controls graduate from MVP to serious emulation.
