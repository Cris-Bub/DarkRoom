# DesignSystem Spec

## Purpose

`DesignSystem/` contains shared SwiftUI design tokens and reusable presentational components for the macOS app.

## Depends On

- SwiftUI.
- `docs/design-system.md` for design language and atomic inventory.

## Affords

- A single source of truth for repeated spacing, typography, icon names, and small UI primitives.
- Consistent visual behavior across sidebar, viewer, inspector, and future panels.

## Responsibilities

- Keep components small, reusable, and presentational.
- Follow atomic design naming and folder placement where it clarifies ownership.
- Prefer native macOS controls and wrap only repeated product-specific patterns.

## Boundaries

- Do not put feature-specific state, folder scanning, image decoding, edit graph behavior, or engine math here.
- Do not add abstractions for one-off UI until reuse or future change leverage is clear.
- Do not use this folder to bypass macOS-native behavior.

## Update Triggers

Update when token groups, atomic levels, reusable components, or design-system ownership rules change.
