# Design System

DarkRoom should feel like a quiet native macOS photo grading workstation: neutral, precise, dense enough for repeated professional use, and visually subordinate to the image. The interface should not feel like a marketing page, a generic dashboard, or a playful consumer editor. It should feel calm, fast, and deliberate.

## Design Language Statement

DarkRoom uses restrained macOS-native controls, neutral surfaces, compact spacing, clear hierarchy, and low-noise typography so users can judge photographs without the UI competing for attention. Color is reserved for image content, status, selection, warnings, and future measurement/scopes. The product should prefer durable professional patterns over decorative novelty.

## Principles

- Image first: the photograph and scopes are the visual priority.
- Native by default: use SwiftUI/AppKit patterns before inventing custom controls.
- Quiet density: keep controls compact and scannable without feeling cramped.
- Single source of truth: shared spacing, typography, labels, and reusable UI components belong in the design system.
- Add slowly: create a token or component only when reuse, consistency, or future change leverage is real.
- Document intent: when a design pattern graduates into the system, update this file and the nearest `SPEC.md`.

## Atomic Structure

### Tokens

Tokens are primitive values used across UI code. They should live in `apps/macos/Sources/DesignSystem`.

Current token groups:

- Spacing: repeated padding and gaps.
- Typography: semantic text styles for panel headers, empty states, and viewer placeholders.
- Iconography: symbolic icon names that should remain consistent across the app.

Future token groups:

- Color roles for chrome, separators, warnings, and status.
- Radius and stroke values if custom surfaces become necessary.
- Motion durations if interactions start animating.

### Atoms

Atoms are small reusable UI elements that do one thing.

Current atoms:

- `DRPanelHeader`: standard compact panel header.
- `DREmptyState`: icon, title, optional message, and optional action button.
- `DRPlaceholderText`: quiet placeholder text for empty content regions.

Candidate atoms:

- Label/value metadata row.
- Icon-only toolbar button wrapper with tooltip.
- Compact numeric control label.

### Molecules

Molecules combine atoms into reusable control groups.

Current molecules:

- None yet.

Candidate molecules:

- Inspector slider row.
- Background picker row.
- Image metadata summary.
- Scope panel header with mode selector.

### Organisms

Organisms are larger feature sections composed from molecules and local state.

Current organisms:

- Sidebar image browser.
- Viewer pane.
- Inspector pane.

Candidate organisms:

- Filmstrip.
- Histogram scope.
- Light adjustment section.
- HCL curve editor.

### Templates

Templates define screen-level structure without feature-specific data.

Current templates:

- Three-panel workstation layout: sidebar, viewer, inspector.

Candidate templates:

- Viewer plus bottom filmstrip.
- Viewer plus scopes.
- Preferences window layout.

### Pages / Scenes

In this macOS app, pages map to windows or major scenes.

Current scenes:

- Main DarkRoom window.

Candidate scenes:

- Preferences.
- Export dialog.
- Keyboard shortcut editor.

## Component Promotion Rule

Before adding a new reusable component, ask:

1. Will this appear in at least two places soon?
2. Does it encode a real product/design decision?
3. Would changing it centrally save future churn?
4. Can it stay small without hiding feature behavior?

If the answer is mostly no, keep the UI local and simple.

## Change Process

When changing UI:

1. Prefer existing tokens/components.
2. If local styling duplicates an existing pattern, move it into the design system.
3. If a new component is added, document it under the right atomic level.
4. If a token changes visual language globally, mention the reason in this file or an ADR if consequential.
5. Keep feature behavior in feature modules; design-system components should be presentational unless intentionally documented.
