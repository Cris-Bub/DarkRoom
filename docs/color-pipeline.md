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

## Early Rules

- Exposure is a scene-linear stop control: `output = input * 2^EV`.
- Contrast is pivoted around middle gray, initially `0.18`.
- Display transforms are separate from edit operations.
- RAW white balance should eventually happen at RAW stage when RAW data is available.

## Open Decisions

- Final working color space.
- OpenColorIO dependency strategy.
- RAW backend scope: Apple RAW only first, or LibRaw as an optional backend.
- How film density and grain controls graduate from MVP to serious emulation.
