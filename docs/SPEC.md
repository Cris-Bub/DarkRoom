# Docs Folder Spec

## Purpose

`docs/` captures architecture, workflow, subsystem behavior, and durable decisions that should outlive any single implementation pass.

## Depends On

- The supplied research and setup direction.
- Current repository structure and source behavior.
- `Agent.md` for documentation process rules.

## Affords

- Shared context for humans and agents before code changes.
- A place to explain why a subsystem exists, not just what files contain.
- Architecture decision records for consequential choices.

## Responsibilities

- Keep high-level subsystem docs current.
- Keep decisions in `docs/decisions/`.
- Keep file and folder spec conventions in `docs/specs/`.
- Keep design language and atomic-design inventory in `docs/design-system.md`.
- Keep color pipeline and viewer accuracy constraints in `docs/color-pipeline.md` until they need a more detailed subsystem doc.

## Boundaries

- Do not duplicate every line of implementation detail.
- Do not use docs to bless responsibilities that are not reflected in source structure.

## Update Triggers

Update relevant docs when project generation, design system, color pipeline, edit graph ordering, masking behavior, scope design, persistence, or ownership boundaries change.
