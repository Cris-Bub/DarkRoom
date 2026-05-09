# Spec Doc Convention

Specs exist to prevent responsibility drift. They should be short, concrete, and close to the code they describe.

## Required Sections

- Purpose.
- Depends on.
- Affords.
- Responsibilities.
- Boundaries.
- Update triggers.

## Placement

- Meaningful folders get a nearby `SPEC.md`.
- Important root files are described in `docs/specs/root-files.md`.
- Generated files do not get specs.
- Trivial leaf files do not need specs unless they become architectural touchpoints.

## Review Heuristic

If an agent can read a spec and confidently decide whether a proposed change belongs in that file or folder, the spec is doing its job.
