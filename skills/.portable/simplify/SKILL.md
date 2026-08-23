---
name: simplify
description: "Clean up the changed code without changing behavior: review the diff for reuse, simplification, efficiency, and altitude issues, then apply the fixes. Quality only, not bug hunting. Portable snapshot of Claude Code's built-in /simplify for hosts without it."
---

# Simplify

You are improving the quality of the changed code, not hunting for bugs (that is code review's job).

Target: the argument if given, else `git diff @{upstream}...HEAD` plus `git diff HEAD` to cover committed and uncommitted changes, falling back to `git diff main...HEAD`.

## Phase 1: Review (4 angles)

If a subagent tool is available, launch 4 independent review agents in parallel, each given the diff and one angle below; otherwise work through all four angles yourself in one pass, and do not skip an angle. Each finding carries `file`, `line`, a one-line summary, and the concrete cost (what is duplicated, wasted, or harder to maintain).

### Reuse

Flag new code that re-implements something the codebase already has: grep shared/utility modules and files adjacent to the change, and name the existing helper to call instead.

### Simplification

Flag unnecessary complexity the diff adds: redundant or derivable state, copy-paste with slight variation, deep nesting, dead code left behind. Name the simpler form that does the same job.

### Efficiency

Flag wasted work the diff introduces: redundant computation or repeated I/O, independent operations run sequentially, blocking work added to startup or hot paths, and long-lived objects built from closures that keep the whole enclosing scope alive. Name the cheaper alternative.

### Altitude

Check that each change is implemented at the right depth, not as a fragile bandaid. Special cases layered on shared infrastructure are a sign the fix isn't deep enough; prefer generalizing the underlying mechanism over adding special cases.

## Phase 2: Apply the fixes

Dedup findings that point at the same line or mechanism, then fix each remaining one directly. Skip any finding whose fix would change intended behavior, require changes well outside the reviewed diff, or that you judge a false positive; note the skip rather than arguing with it. Finish with a brief summary of what was fixed and what was skipped (or confirm the code was already clean).
