# Molecules Spec

## Purpose

`Molecules/` contains reusable UI groups composed from atoms and native controls.

## Depends On

- SwiftUI.
- Design-system tokens and atoms.

## Affords

- Repeated inspector control groups such as collapsible sections and adjustment rows.
- Collapsible section headers with optional feature-supplied reset actions, exposed as compact icon buttons and context-menu items.
- Adjustment rows and sliders that can report active drag or numeric-entry state to feature modules for interactive preview scheduling and carry plain-language help text.
- Clickable adjustment values that temporarily become bounded numeric entry fields.
- Optional per-row reset affordances supplied by feature modules when a control has a clear default value.
- Compact help popover icons for developer-facing controls whose tooltip timing needs to be explicit.

## Responsibilities

- Keep molecules presentational or narrowly interactive.
- Accept data and bindings from feature modules instead of owning feature state.
- Surface generic interaction lifecycle callbacks, reset affordances, disabled states, and help text without knowing what the feature does with them.
- Keep help popovers presentational: feature modules supply the text and decide where the icon appears.
- Clamp direct numeric entry through the same range supplied to the slider.
- Clamp reset values through the same range supplied to the slider.

## Boundaries

- Do not add feature workflows, folder/image loading, edit graph behavior, or persistence here.
- Do not create molecules preemptively without a clear near-term reuse case.

## Update Triggers

Update when molecule inventory, interaction scope, or ownership changes.
