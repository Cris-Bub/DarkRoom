# RawDecoding Spec

## Purpose

`RawDecoding/` owns swappable RAW decoding interfaces and V1's Apple RAW implementation.

## Depends On

- Core Image for the Apple `CIRAWFilter` implementation.
- Core Graphics for orientation and color metadata values.
- `LocalImageFile` only for file-extension routing.

## Affords

- A `RawDecoder` protocol that keeps app code from depending directly on Apple RAW everywhere.
- `AppleRawDecoder` as the V1 shipping RAW path.
- Data structures that can later be reused by a LibRaw decoder or mock test decoder.

## Responsibilities

- Decide whether a decoder can handle a file.
- Decode RAW files into a color-managed image candidate plus metadata.
- Surface orientation, white balance, camera, and bit-depth metadata as available.
- Keep Apple-specific RAW setup isolated.

## Boundaries

- Do not apply the user edit graph here.
- Do not own viewer or export transforms.
- Do not implement custom camera profiles here.
- Do not make Apple RAW the only architecture path; LibRaw should be addable without rewriting viewer/export code.

## Update Triggers

Update when RAW decoder protocol methods, decoded metadata shape, Apple RAW defaults, or LibRaw integration boundaries change.
