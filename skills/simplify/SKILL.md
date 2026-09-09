---
name: simplify
description: "Improve changed code through reuse, simplification, efficiency, and ownership review, then apply behavior-preserving fixes."
---

# Simplify

Review quality; material defects belong to `/code-review`.

Target: the argument if given, else `git diff @{upstream}...HEAD` plus `git diff HEAD` to cover committed and uncommitted changes, falling back to `git diff main...HEAD`.

## Phase 1: Review (4 angles)

Use one fresh reviewer for all four angles. Split across agents only when the diff exceeds about 300 changed lines and spans independent modules; without agents, cover all four yourself. Give the reviewer only the diff, explicit constraints, and authorized implementation stage. Exclude session history, rationale, and prior agent output. Review user edits, including deletions, as the current design. Each finding names the file, line, issue, concrete cost, and existing or simpler alternative.

### Reuse

Find reimplemented behavior in adjacent and shared modules; identify the existing implementation to reuse.

### Simplification

Find redundant or derivable state, duplicated logic, deep nesting, and dead code.

### Efficiency

Find repeated computation or IO, sequential independent operations, blocking startup or hot-path work, and closures retaining unnecessary long-lived state.

### Altitude

Find special cases whose invariant belongs in a shared mechanism; keep the fix at its owning boundary. Check that replacing outer implementations under unchanged contracts leaves inner code and explanations valid; relocate violations.

## Phase 2: Apply the fixes

Deduplicate findings by mechanism and apply them directly; delegate to clean agents with non-overlapping scopes only under the same large-diff condition, then check the combined diff without reimplementing accepted fixes. Preserve intentional stubs and review pauses at the authorized stage. Skip false positives and fixes that change behavior or exceed scope. Re-read before editing; review later user edits as new code. Report fixes and skips briefly.
