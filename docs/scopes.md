# Scopes

Scopes are part of DarkRoom's product identity, not a late decorative feature.

## Target Scopes

- Histogram.
- Waveform.
- RGB parade.
- Vectorscope.

Future additions may include CIE chromaticity and gamut warnings.

## Design Rules

- Scopes should sample from defined pipeline stages.
- Scope math should have CPU reference tests where practical.
- Metal may own fast rendering, but the sampling contract belongs in documented engine behavior.
- UI chrome should stay calm and let the image and measurements dominate.

## MVP Status

No scope implementation exists yet. Milestone 2 should add histogram and either waveform or RGB parade.
