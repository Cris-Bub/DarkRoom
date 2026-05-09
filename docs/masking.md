# Masking

Masks should become a graph of selection operations, not a flat list of bitmaps.

## Intended Model

Mask nodes may include:

- Brush strokes as raster tiles.
- Linear gradients.
- Radial gradients.
- Hue, saturation, and luminance ranges.
- Future subject or sky selections.

Composition should support:

- Union.
- Subtract.
- Intersect.
- Invert.
- Feather.

## Boundary

Swift UI may present mask controls and previews. Rust should own portable mask graph schema and boolean behavior. GPU shaders may accelerate evaluation once CPU reference behavior is defined.

## MVP Status

No mask implementation exists yet. Do not add UI-only mask behavior without defining the graph owner and test strategy.
