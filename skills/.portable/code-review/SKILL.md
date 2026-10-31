---
name: code-review
description: "Find material correctness, contract, test, compatibility, and artifact defects in changed code; verify candidates and report evidence."
---

# Code Review

Report material defects, excluding style preferences. Target resolution as in `/simplify`: the argument if given, else the branch diff plus uncommitted changes. Include explicit constraints, the authorized implementation stage, and, if present, ledger paths with applicable sections (see `Agent ledgers`) in review inputs. Contracted stubs at intermediate reviews are intentional; hidden assumptions, contradictory contracts, and stubs remaining at completion are findings.

## Phase 1: Find (5 angles)

- **Correctness.** Wrong results or crashes with a concrete failure scenario.
- **Contracts.** Broken invariants; key, uniqueness, and join grain; temporal and timezone boundaries; nullability; validation silently loosened instead of the data shape fixed; applicable ledger contracts the diff drops or weakens; changes outside authorized scope.
- **Tests.** Tautologies (the test controls both sides), mirrors (fails on harmless change), and contract branches with no test that would fail. Survivors from a mutator run on the reviewed diff, in the worktree's `.metrics/mutate/` or retained with task evidence, are candidates; reports from earlier code are not.
- **Compatibility.** Breaking changes to a public surface with silent survivors (old names, schemas, serialized shapes) or undisclosed consumer impact.
- **Artifacts.** Docstrings, docs, or PR text that misstate what the code does.

## Phase 2: Verify

Deduplicate defects by mechanism, then use one fresh verifier for the remaining candidates. Split substantial, independently reviewable scopes when useful; without agents, re-derive each candidate from code. Verify adversarially and classify as CONFIRMED, PLAUSIBLE, or REFUTED; drop REFUTED.

## Phase 3: Report

Most severe first: file, line, the defect in one sentence, and the concrete failure scenario. State what was reviewed and any angle that could not be covered.
