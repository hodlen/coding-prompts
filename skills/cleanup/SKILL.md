---
name: cleanup
description: "Audit scope, simplify changes, and clean durable artifacts before merge or at a mid-work checkpoint. Accepts an explicit target."
---

# Cleanup

Target: the supplied argument (the gate passes its baseline SHA), else the branch diff plus staged, unstaged, and untracked changes.

Pass A uses a clean agent given only the diff, the request verbatim, the plan if any, explicit constraints, the current implementation stage with its approved scope, and the `Tests as contracts` policy. Pass C uses a fresh agent given only the final diff, changed artifacts, repository-visible references, and the `Durable artifacts` policy. Exclude session rationale and prior agent output. Review user edits, including deletions, as the current design. Include edits made during cleanup in the review; re-read before editing. Agents edit and verify directly, returning conflicts or genuine ambiguity to the main agent.

**A. Scope and contracts.** Check the request, constraints, and authorized stage. Check that replacing outer implementations under unchanged contracts leaves inner code and explanations valid; relocate violations. Preserve contracted stubs at intermediate reviews; flag hidden decisions, invented success values, work beyond the approved stage, and names that describe the mechanism rather than the domain role. At completion, require resolved stubs and approved or explicitly waived reviews. Audit changed tests under `Tests as contracts` and mutation-check the decisions in scope. Remove unrelated edits, formatting churn, unrequested features or tests, and impossible-state guards. Verify deletions by search and GitHub paragraphs for hard wraps. Apply fixes within the authorized stage.

**B. `/simplify`** on the same target and authorized stage.

**C. Durable artifacts.** Apply the supplied policy, preserving meaning and reporting ambiguity. Skip mid-work when no durable artifacts changed.

Before returning, re-read the tree and review new edits; reuse findings for unchanged code.
