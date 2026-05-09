# Atoms Spec

## Purpose

`Atoms/` contains the smallest reusable DarkRoom UI components.

## Depends On

- SwiftUI.
- Design-system tokens.

## Affords

- Consistent primitive UI pieces for feature views.
- A place to centralize repeated presentational patterns without absorbing feature behavior.

## Responsibilities

- Keep atoms small and generally stateless.
- Accept content, labels, bindings, or closures from callers.
- Encode reusable visual language described in `docs/design-system.md`.

## Boundaries

- Do not perform folder access, image loading, edit math, persistence, or feature orchestration.
- Do not create atoms for one-off styling unless the pattern is expected to spread soon.

## Update Triggers

Update when atom responsibilities, naming rules, or token dependencies change.
