---
name: code-review
description: "Find material correctness, contract, test, compatibility, and artifact defects in changed code; verify candidates and report evidence."
---

# Code Review

Report material defects, excluding style preferences. Target resolution as in `/simplify`: the argument if given, else the branch diff plus uncommitted changes. Include explicit constraints and the authorized implementation stage in review inputs. Contracted stubs at intermediate reviews are intentional; hidden assumptions, contradictory contracts, and stubs remaining at completion are findings.

## Phase 1: Find (5 angles)

- **Correctness.** Wrong results or crashes with a concrete failure scenario.
- **Contracts.** Broken invariants; key, uniqueness, and join grain; temporal and timezone boundaries; nullability; validation silently loosened instead of the data shape fixed.
- **Tests.** Tautologies (the test controls both sides), mirrors (fails on harmless change), and contract branches with no test that would fail.
- **Compatibility.** Breaking changes to a public surface with silent survivors (old names, schemas, serialized shapes) or undisclosed consumer impact.
- **Artifacts.** Docstrings, docs, or PR text that misstate what the code does.

## Phase 2: Verify

Deduplicate defects, then adversarially verify each in a separate subagent when available, or re-derive it from code. Classify as CONFIRMED, PLAUSIBLE, or REFUTED; drop REFUTED.

## Phase 3: Report

Most severe first: file, line, the defect in one sentence, and the concrete failure scenario. State what was reviewed and any angle that could not be covered.
