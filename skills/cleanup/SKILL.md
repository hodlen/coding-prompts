---
name: cleanup
description: "Audit scope, simplify changes, and clean durable artifacts before merge or at a mid-work checkpoint. Accepts an explicit target."
---

# Cleanup

Target: the supplied argument (the gate passes its baseline SHA), else the branch diff plus staged, unstaged, and untracked changes.

Pass A uses a clean agent given only the diff, the request verbatim, the plan if any, explicit constraints, the implementation stage with its approved scope, and the `Tests as contracts` policy; Pass C a fresh agent given only the final diff, changed artifacts, repository-visible references, and the `Durable artifacts` policy. Exclude session rationale and prior agent output. Review user edits, including deletions, as the current design. Agents edit and verify directly, returning conflicts or genuine ambiguity to the main agent. While a pass runs nobody else edits its files: the main agent waits, and the pass stops when the user edits them. Revert mutations by inverse edit, never from a snapshot.

**A. Scope and contracts.** Check the request, constraints, and authorized stage. Under unchanged contracts, keep inner code and explanations valid when outer implementations change. Preserve contracted intermediate stubs; flag hidden decisions, invented success, and names lacking domain meaning. Completion requires resolved stubs and approved or explicitly waived reviews. Keep helpers and constants local to their sole consumer unless demonstrated lifetime or identity requirements prevent it; reject manufactured references, remove unused names, and localize survivors. Table changed tests (decision, rejected alternative, entry point, substitutes); remove tests lacking a rejected alternative; test mocked decisions directly and move CLI/HTTP/handler decision tests to operations. Mutation-check scoped decisions. Verify wiring and protocols through authorized live runs; report evidence or unavailable checks. Remove unrelated edits, formatting churn, unrequested features or tests, and impossible-state guards. Verify deletions by search and GitHub paragraphs for hard wraps. Fix within the authorized stage.

**B. `/simplify`** on the same target and authorized stage.

**C. Durable artifacts.** Review every artifact in the target scope, including earlier-session changes, under `Durable artifacts`. Check code-to-spec references, one-minute overviews, and domain definitions; remove code-restating comments and narrative logs, preserving diagnostic evidence. Resolve negations and decision stamps; report ambiguity. Skip mid-work only when no durable artifacts in scope need review.

Before returning, re-read the tree and review new edits; reuse findings for unchanged code.
