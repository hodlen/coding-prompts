---
name: simplify
description: "Improve changed code through reuse, simplification, efficiency, and ownership review, then apply behavior-preserving fixes."
---

# Simplify

Review quality; material defects belong to `/code-review`.

Target: the argument if given, else `git diff @{upstream}...HEAD` plus `git diff HEAD` to cover committed and uncommitted changes, falling back to `git diff main...HEAD`.

## Phase 1: Review (4 angles)

Before review, resolve the target to existing source files supported by the tools, excluding tests, generated files and dependencies. For a ref target, compare its merge base with HEAD to the worktree and include untracked source files. Native `--changed` covers working-tree changes only; it does not select the full branch diff. Skip analysis when no supported source files are in scope.

Metrics belong to the analyzed worktree in `.metrics/`, excluded through the global Git ignore file by `install.py`. Use reports whose source and analysis inputs match the reviewed code; retained reports are evidence only while those inputs remain applicable.

Run from the worktree root and collect reports for the reviewer:

```sh
crapper --coverage-command '<project coverage command>' <source files>
dryer
```

Use an explicit project coverage command, or `--no-coverage` for complexity alone. The command must write the reports crapper reads (`crapper --help`). Check coverage failures and all-zero reports explicitly: a successful exit does not establish valid coverage. Record unavailable coverage or tools as verification gaps. Run dryer across the tree so unchanged implementations remain comparison partners; review the pairs involving the target files.

Record report paths in the ledger and retain evidence needed for resumption or acceptance in the durable task record.

Signals are candidates, not targets. A CRAP score above 10 asks whether a promised behavior lacks a test or one function mixes decisions; accept case dispatch with its reason. A duplicate pair feeds Reuse and the third-occurrence rule. Never split, extract, or add tests only to move a score.

Use one fresh reviewer for all four angles. Without agents, cover all four angles yourself. Split across agents only when the diff exceeds about 300 changed lines and spans independent modules. Give the reviewer the diff, authorized scope, explicit constraints, accepted decisions and their reasons, and ledger paths with applicable sections (see `Agent ledgers`) if present. Verify conclusions independently. Review user edits, including deletions, as the current design. Each finding names the file, line, issue, concrete cost, and existing or simpler alternative.

### Reuse

Find reimplemented behavior in adjacent and shared modules; name the facility to reuse and separate its guarantees from unrelated architecture.

### Simplification

Find redundant state, duplicate logic, deep nesting, dead code, and unnecessarily broad visibility. Judge simplification by total production-path cost, including conversions, validation, and caller effort; preserve contracted capabilities.

### Efficiency

Find repeated computation or IO, sequential independent operations, blocking startup or hot-path work, and closures retaining unnecessary long-lived state.

### Altitude

Find special cases whose invariant belongs in a shared mechanism; keep the fix at its owning boundary. When that mechanism lies outside authorized scope, report a follow-up instead of relocating. Check that replacing outer implementations under unchanged contracts leaves inner code and explanations valid; relocate violations.

## Phase 2: Apply the fixes

Deduplicate findings by mechanism and apply them directly; delegate to clean agents with non-overlapping scopes only under the same large-diff condition, then check the combined diff without reimplementing accepted fixes. Preserve intentional stubs and required review boundaries. Skip false positives and fixes that change behavior or exceed authorized scope; report skipped scope findings as follow-ups. Re-read before editing; review later user edits as new code. Report fixes and skips briefly.
