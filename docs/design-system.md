# Design System

DarkRoom should feel like a quiet minimalist beautiful sleek native macOS photo grading workstation: neutral, precise, dense enough for repeated professional use, and visually subordinate to the image. The interface should not feel like a marketing page, a generic dashboard, or a playful consumer editor. It should feel calm, fast, and deliberate.

## Design Language Statement

DarkRoom uses restrained custom workstation controls, neutral surfaces, compact spacing, clear hierarchy, and low-noise typography so users can judge photographs without the UI competing for attention. Native macOS behavior still matters for system affordances, menus, windows, file access, keyboard focus, and accessibility, but core editing surfaces should express a deliberate DarkRoom design language instead of exposing raw platform defaults everywhere. Color is reserved for image content, status, selection, warnings, and future measurement/scopes. The product should prefer durable professional patterns over decorative novelty.

## Principles

- Image first: the photograph and scopes are the visual priority.
- Custom by intention: prefer documented DarkRoom components for repeated editing workflows, especially sliders, rails, panels, scopes, metadata, and grading controls.
- Native where it earns trust: use platform controls for OS-level behaviors, semantic pickers, menus, dialogs, text entry, focus, and accessibility when they match the product language or can be wrapped cleanly.
- Quiet density: keep controls compact and scannable without feeling cramped.
- Single source of truth: shared spacing, typography, labels, and reusable UI components belong in the design system.
- Add slowly: create a token or component only when reuse, consistency, or future change leverage is real.
- Document intent: when a design pattern graduates into the system, update this file and the nearest `SPEC.md`.

## Atomic Structure

### Tokens

Tokens are primitive values used across UI code. They should live in `apps/macos/Sources/DesignSystem`.

Current token groups:

- Spacing: repeated padding and gaps.
- Typography: semantic text styles for panel headers, inspector titles, adjustment rows, empty states, and viewer placeholders.
- Iconography: symbolic icon names that should remain consistent across the app.
- Palette: neutral inspector, rail, control, border, and text roles.

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
- `DRIconRailButton`: icon-only rail button with selected state and tooltip.

Candidate atoms:

- Label/value metadata row.
- Compact numeric control label.

### Molecules

Molecules combine atoms into reusable control groups.

Current molecules:

- `DRCollapsibleSection`: Lightroom-like disclosure section for inspector groups, with optional feature-supplied header reset actions.
- `DRAdjustmentRow`: label, clickable bounded value entry, and custom adjustment slider.
- `DRAdjustmentSlider`: horizontal adjustment control with a bordered circular knob whose fill matches the inspector surface.

Candidate molecules:

- Viewer proof/background picker row.
- Image metadata summary.
- Scope panel header with mode selector.

### Organisms

Organisms are larger feature sections composed from molecules and local state.

Current organisms:

- Sidebar image browser.
- Viewer pane.
- Inspector pane with edit/crop/mask rail and subtle image details panel.
- Inspector histogram with overlapping luminance/RGB channels and shadow/highlight clipping indicators.
- Toolbar export action with compact progress/status feedback.

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
2. If native controls are used directly, make sure they fit the documented product language or are operating system affordances where native behavior is the value.
3. If local styling duplicates an existing pattern, move it into the design system.
4. If a new component is added, document it under the right atomic level.
5. If a token changes visual language globally, mention the reason in this file or an ADR if consequential.
6. Keep feature behavior in feature modules; design-system components should be presentational unless intentionally documented.

## Inspector Pattern

The inspector uses a right-side mode rail for major editing pages. `Edit` is the default page; `Crop` and `Mask` are placeholders until those tools exist. Image details do not belong inside edit-control sections. They are revealed from the bottom rail info button and shown as a small, low-prominence panel so metadata does not compete with editing controls.

The inspector histogram sits above the edit controls. The body is drawn as a per-bin stack that goes gray where all three RGB channels overlap, fades to a muted yellow/cyan/magenta where two channels overlap, and reaches a muted single-channel color where only one channel reaches that height. Pure channel color is reserved for the thin top outlines and the small top-corner clipping indicators. The histogram should reflect the current edited image and selected `View As` target rather than source-only pixels, and it should keep the previous graph visible while live slider updates render.

The Viewer section uses `View As` for output proofing language. It should avoid lower-level wording like "display profile" because the physical display profile is an implementation detail, not the creative/output target the user is choosing.

Edit sections should be collapsible. V1 tonal controls are Exposure, Contrast, Pivot, Highlights, Shadows, Whites, and Blacks. Adjustment sliders use subdued labels and numeric values with a circular knob: bordered, light stroke, and filled with the local inspector background so the handle reads like a control rather than a filled badge. Numeric value readouts should be clickable and temporarily become compact entry fields that clamp to the same bounds as the slider. Sliders and numeric entry should surface active editing state to feature code so viewer previews can switch into a faster interactive render mode while edits are in progress. Tooltips should be plain-language descriptions of the tonal intent, not implementation terms.

Edit and developer-tuning sections may expose section-level resets from the collapsible header. Individual adjustment rows may also expose a compact reset icon when the feature supplies an exact default value. Developer-facing controls may expose a small `info.circle` popover icon when normal tooltip timing is too hard to trigger. The reusable components own only the small reset/help affordances; the feature module decides which fields reset, which help text appears, and when actions are disabled.

Editing controls must visibly enter a read-only state when no selected image has a rendered preview for the current display. The disabled state should preserve layout and hierarchy, but reduce contrast enough that users do not mistake unavailable controls for active grading state.

Export should stay quiet and native at V1: a toolbar action opens the macOS save panel, reuses the current `View As` output target, and shows compact status instead of introducing a large custom export surface before presets, resizing, metadata policy, or batch behavior exist.
