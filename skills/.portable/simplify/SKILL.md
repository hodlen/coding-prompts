---
name: simplify
description: "Improve changed code through reuse, simplification, efficiency, and ownership review, then apply behavior-preserving fixes."
---

# Simplify

Review quality; material defects belong to `/code-review`.

Target: the argument if given, else `git diff @{upstream}...HEAD` plus `git diff HEAD` to cover committed and uncommitted changes, falling back to `git diff main...HEAD`.

## Phase 1: Review (4 angles)

Use one fresh reviewer covering all four angles by default. Split substantial, independently reviewable scopes or angles across agents when useful; without agents, cover all four yourself. Give reviewers only the diff, assigned scope and angles, explicit constraints, and authorized implementation stage. Exclude session history, rationale, and prior agent output. Each finding names the file, line, issue, concrete cost, and existing or simpler alternative.

### Reuse

Find reimplemented behavior in adjacent and shared modules; identify the existing implementation to reuse.

### Simplification

Find redundant or derivable state, duplicated logic, deep nesting, and dead code.

### Efficiency

Find repeated computation or IO, sequential independent operations, blocking startup or hot-path work, and closures retaining unnecessary long-lived state.

### Altitude

Find special cases whose invariant belongs in a shared mechanism; keep the fix at its owning boundary.

## Phase 2: Apply the fixes

Deduplicate findings by mechanism. Assign independent fixes to clean agents with non-overlapping scopes; they edit and verify directly. The main agent handles overlaps and cross-cutting decisions, then checks the combined diff without reimplementing accepted fixes. Preserve intentional stubs and review pauses at the authorized stage. Skip false positives and fixes that change behavior or exceed scope. Report fixes and skips briefly.
