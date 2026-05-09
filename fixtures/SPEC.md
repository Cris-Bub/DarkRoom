# Fixtures Folder Spec

## Purpose

`fixtures/` stores offline test images, LUTs, and golden outputs used to validate engine math, renderer behavior, and import/export paths.

## Depends On

- Local repository files only.
- Future Git LFS policy if large image fixtures are added.

## Affords

- Repeatable tests without cloud services.
- Visual and numeric regression checks for grading behavior.

## Responsibilities

- Keep fixture provenance documented.
- Keep images small enough for normal development unless Git LFS is intentionally enabled.
- Separate source images, golden outputs, and LUTs.

## Boundaries

- Do not store user photo libraries here.
- Do not add large binary files casually.

## Update Triggers

Update when fixture categories, storage policy, licensing expectations, or golden comparison strategy changes.
