# Color Pipeline

DarkRoom should be scene-referred and wide-gamut internally, with output proofing and display rendering handled as separate stages.

## Starting Position

The first implemented code is CPU reference math for exposure, pivoted contrast, and V1 light-control parameter mapping in `darkroom_core`. These functions are intentionally simple and testable. They establish the pattern for future color work: define behavior, write a CPU reference, then allow GPU paths to match it.

## Intended Pipeline

1. Decode image and metadata through Image I/O or a RAW backend.
2. Normalize into a scene-referred working representation.
3. Apply non-destructive edit recipe operations.
4. Convert through the selected preview/export target.
5. Render viewer output through the current monitor profile or write the export target as an embedded-profile file.
6. Generate scopes from defined pipeline taps, not arbitrary UI pixels.

## V1 Preview Targets

The viewer has a `View As` control with two V1 output-proof targets:

- `Web / Instagram`: sRGB output proof. This is the default because it matches normal web, social, and general client delivery expectations.
- `Apple Display P3`: Display P3 output proof for Apple-device and wide-gamut delivery expectations.

Preview targets are not display profiles. A preview target describes the output condition being simulated. The current display profile describes how the physical Mac display must be driven to show that output condition correctly.

## Viewer And Export Accuracy Baseline

The first viewer and export implementations now share `ImagePipeline/` instead of relying on `NSImage(contentsOf:)` or cached viewer pixels.

- RAW files are routed through the `RawDecoder` protocol. V1 ships `AppleRawDecoder`, backed by Apple's `CIRAWFilter`, with draft mode off, lens correction enabled when supported, gamut mapping enabled, and extended dynamic range output disabled for the current SDR viewer baseline.
- Raster files are decoded through Image I/O, preserving source color tags where available and treating untagged raster input as sRGB.
- Core Image renders through Linear ROMM RGB, applies the V1 light recipe using Rust-derived parameter math, then proof-converts to the selected preview/export target.
- Viewer preview renders through a Metal-backed Core Image surface sized to the current viewer bounds and adds one final display conversion into the current window/display color space. During active slider drags, the viewer uses a lower-resolution interactive working image and then renders the normal viewer-resolution preview when the drag ends.
- Interactive viewer updates reuse prepared source data and render directly into the Metal drawable so slider drags do not queue stale AppKit image replacements.
- Inspector histograms render a bounded analysis image from source plus recipe through the same edit and preview-target proofing path, but stop before the viewer-only display-profile conversion. During slider drags, the histogram skips Core Image entirely: it caches a small neutral RGBA8 buffer once per file/preview-target and runs the V1 light recipe plus binning in a single Rust C ABI call. When dragging ends, the canonical pipeline render+bin path runs to refresh the histogram at the settled analysis size and color path.
- Export stops at the selected output target and writes JPEG, PNG, or TIFF through Image I/O with the rendered output color space.
- The viewer observes window display/backing color-space changes and invalidates the preview cache when the app moves between displays or the display profile changes.
- The rendered viewer image is display-referred preview data only. It must not become the export source or the persistent edit representation.

This is display-management accuracy, not Lightroom visual matching. Lightroom/Camera Raw apply Adobe RAW profiles, defaults, sharpening, denoise, highlight behavior, and tone curves before the user moves a slider. DarkRoom needs its own declared RAW baseline first, then later camera/profile options if we want Adobe-like, camera-matching, or filmic starting points.

## Early Rules

- Exposure is a scene-linear stop control: `output = input * 2^EV`.
- Contrast is pivoted around middle gray, initially `0.18`.
- Highlights and shadows should behave like bounded tone-shaping controls, not independent high/low gain multipliers. Extreme settings must preserve tone ordering, avoid dragging highlights below middle gray, and avoid lifting true black into muddy gray.
- Display transforms are separate from edit operations.
- RAW white balance should eventually happen at RAW stage when RAW data is available.
- Viewer readiness should gate edit controls; users should not be able to move grading controls when the selected image has not decoded into the current display preview.
- The histogram should update with current light edits and `View As` target, including shadow/highlight clipping indicators derived from the proofed analysis image. It should preserve the previous graph while a newer slider position is rendering instead of flashing into a loading state.
- Export must re-render from source plus edit recipe. It must not write cached viewer pixels.
- Exports must carry their output color profile; silent untagged export is a bug.
- V1 export target equals the current `View As` target until a dedicated export dialog/preset system exists.
- Non-neutral edit recipes must persist outside the original image file so viewer and export can recover the same recipe after app relaunch.

## Open Decisions

- Whether Linear ROMM RGB remains the long-term working space once the Rust/Metal graph owns more of the pipeline.
- OpenColorIO dependency strategy.
- LibRaw integration timing and how much metadata should be common across Apple RAW and LibRaw.
- Whether the default RAW tone baseline should be Apple RAW defaults, a neutral scene-linear profile, camera-matching profiles, or a DarkRoom-authored look.
- EDR/HDR viewer mode policy for XDR-capable displays.
- How film density and grain controls graduate from MVP to serious emulation.
