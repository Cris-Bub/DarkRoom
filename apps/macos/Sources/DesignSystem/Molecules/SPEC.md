# Molecules Spec

## Purpose

`Molecules/` is reserved for reusable UI groups composed from atoms and native controls.

## Depends On

- SwiftUI.
- Design-system tokens and atoms.

## Affords

- A place for repeated control groups once they appear in multiple feature panes.

## Responsibilities

- Keep molecules presentational or narrowly interactive.
- Accept data and bindings from feature modules instead of owning feature state.

## Boundaries

- Do not add feature workflows, folder/image loading, edit graph behavior, or persistence here.
- Do not create molecules preemptively without a clear near-term reuse case.

## Update Triggers

Update when the first molecule is added or when molecule ownership changes.
