---
name: code-review
description: "Review the changed code for material defects (correctness, contracts, tests, compatibility, misleading artifacts), adversarially verify findings, then report. Portable equivalent of Claude Code's built-in /code-review for hosts without it."
---

# Code Review

Report only material defects; no style or quality preferences (that is simplify/cleanup's job). Target resolution as in simplify: the argument if given, else the branch diff plus uncommitted changes.

## Phase 1: Find (5 angles)

- **Correctness.** Inputs or state where the code produces a wrong result or crash; every candidate needs a concrete failure scenario, not a suspicion.
- **Contracts.** Broken invariants; key, uniqueness, and join grain; temporal and timezone boundaries; nullability; validation silently loosened instead of the data shape fixed.
- **Tests.** Tautologies (the test controls both sides), mirrors (fails on harmless change), and contract branches with no test that would fail.
- **Compatibility.** Breaking changes to a public surface with silent survivors (old names, schemas, serialized shapes) or undisclosed consumer impact.
- **Artifacts.** Docstrings, docs, or PR text that misstate what the code does.

## Phase 2: Verify

Dedup candidates pointing at the same defect, then adversarially verify each one: a subagent per finding where available, otherwise re-derive it from the code yourself. Verdict is CONFIRMED, PLAUSIBLE, or REFUTED; drop REFUTED.

## Phase 3: Report

Most severe first: file, line, the defect in one sentence, and the concrete failure scenario. State what was reviewed and any angle that could not be covered.
