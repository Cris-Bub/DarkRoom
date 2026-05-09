# Molecules Spec

## Purpose

`Molecules/` contains reusable UI groups composed from atoms and native controls.

## Depends On

- SwiftUI.
- Design-system tokens and atoms.

## Affords

- Repeated inspector control groups such as collapsible sections and adjustment rows.

## Responsibilities

- Keep molecules presentational or narrowly interactive.
- Accept data and bindings from feature modules instead of owning feature state.

## Boundaries

- Do not add feature workflows, folder/image loading, edit graph behavior, or persistence here.
- Do not create molecules preemptively without a clear near-term reuse case.

## Update Triggers

Update when molecule inventory, interaction scope, or ownership changes.
