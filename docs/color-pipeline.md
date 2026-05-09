# Color Pipeline

DarkRoom should be scene-referred and wide-gamut internally, with display rendering handled as a separate stage.

## Starting Position

The first implemented code is CPU reference math for exposure and pivoted contrast in `darkroom_core`. These functions are intentionally simple and testable. They establish the pattern for future color work: define behavior, write a CPU reference, then allow GPU paths to match it.

## Intended Pipeline

1. Decode image and metadata through Image I/O or a RAW backend.
2. Normalize into a scene-referred working representation.
3. Apply non-destructive edit recipe operations.
4. Render through a display transform aware of the current monitor profile.
5. Generate scopes from defined pipeline taps, not arbitrary UI pixels.

## Viewer Accuracy Baseline

The first viewer implementation now has an explicit preview render boundary instead of relying on `NSImage(contentsOf:)`.

- RAW files are routed through Apple's `CIRAWFilter` when available, with draft mode off, lens correction enabled when supported, gamut mapping enabled, and extended dynamic range output disabled for the current SDR viewer baseline.
- Raster files are decoded through Image I/O, preserving source color tags where available and treating untagged raster input as sRGB.
- Core Image renders through an extended-linear Display P3 working space into the current window/display color space.
- The viewer observes window display/backing color-space changes and invalidates the preview cache when the app moves between displays or the display profile changes.
- The rendered viewer image is display-referred preview data only. It must not become the export source or the persistent edit representation.

This is display-management accuracy, not Lightroom visual matching. Lightroom/Camera Raw apply Adobe RAW profiles, defaults, sharpening, denoise, highlight behavior, and tone curves before the user moves a slider. DarkRoom needs its own declared RAW baseline first, then later camera/profile options if we want Adobe-like, camera-matching, or filmic starting points.

## Early Rules

- Exposure is a scene-linear stop control: `output = input * 2^EV`.
- Contrast is pivoted around middle gray, initially `0.18`.
- Display transforms are separate from edit operations.
- RAW white balance should eventually happen at RAW stage when RAW data is available.
- Viewer readiness should gate edit controls; users should not be able to move grading controls when the selected image has not decoded into the current display preview.

## Open Decisions

- Final working color space.
- OpenColorIO dependency strategy.
- RAW backend scope: Apple RAW only first, or LibRaw as an optional backend.
- Whether the default RAW tone baseline should be Apple RAW defaults, a neutral scene-linear profile, camera-matching profiles, or a DarkRoom-authored look.
- EDR/HDR viewer mode policy for XDR-capable displays.
- How film density and grain controls graduate from MVP to serious emulation.
