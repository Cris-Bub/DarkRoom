# Shaders Folder Spec

## Purpose

`shaders/` contains future GPU shader source, starting with Metal.

## Depends On

- Metal toolchain through Xcode.
- CPU reference behavior from Rust crates or documented algorithms.
- Renderer architecture docs.

## Affords

- A dedicated place for performance-critical viewer, scopes, masks, and color operations.

## Responsibilities

- Keep shader files focused on GPU execution.
- Mirror behavior documented and tested elsewhere when possible.
- Avoid burying algorithm decisions only in shader code.

## Boundaries

- Do not put Swift view code or Rust crate source here.
- Do not make shaders the only implementation of critical image math.

## Update Triggers

Update when shader ownership, supported backends, or CPU/GPU parity expectations change.
