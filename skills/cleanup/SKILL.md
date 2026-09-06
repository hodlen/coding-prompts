---
name: cleanup
description: "Audit scope, simplify changes, and clean durable artifacts before merge or at a mid-work checkpoint. Accepts an explicit target."
---

# Cleanup

Use a supplied target. Otherwise compare the pushed frontier (the current branch's upstream tip, or the corresponding remote-tracking tip in a detached worktree) with the latest valid `cleanup-reviewed-through: <short SHA>` in this task and use the newer applicable commit. Treat pushed commits as stable. If neither exists, fall back to the remote-default fork point (`git merge-base --fork-point`, then `git merge-base`) as a last resort. Review the frontier-to-worktree diff, including unpushed commits and staged, unstaged, and untracked changes; never persist checkpoints.

Before Pass A, the main agent selects the remaining mutation scope under `Tests as contracts` from the general instructions. Pass A uses a clean agent given only that policy and scope, the diff, original request verbatim, plan if any, explicit constraints, and current implementation stage with its approved scope. Pass C uses a fresh agent given only the final diff, changed artifacts, repository-visible references, and the general `Durable artifacts` policy. Exclude session rationale and prior agent output. Assign non-overlapping local scopes; agents edit and verify directly, returning conflicts or genuine ambiguity to the main agent.

**A. Scope and constraints.** Check the request, constraints, and authorized stage. Preserve contracted stubs at intermediate reviews; flag hidden decisions, invented success values, and work beyond the approved stage. At completion, require resolved stubs and approved or explicitly waived reviews. Audit changed tests under `Tests as contracts`; perform mutation checks only for the assigned decisions. Remove unrelated edits, formatting churn, unrequested features or tests, and impossible-state guards. Verify deletions by search and GitHub paragraphs for hard wraps. Apply mechanical fixes; report judgment calls.

**B. `/simplify`** on the same target and authorized stage.

**C. Durable artifacts.** Apply the supplied policy, preserving meaning and reporting ambiguity. Skip mid-work when no durable artifacts changed.

Before returning, re-read HEAD and staged, unstaged, and untracked changes, including user progress and cleanup's edits. Reconcile mutation evidence with this final state and check any newly affected decisions. Report later changes as unreviewed. End with:

`cleanup-reviewed-through: <short SHA>`

`cleanup-reviewed-dirty: staged=<accepted|none|unreviewed> unstaged=<...> untracked=<...>`

The main agent may advance the reviewed frontier through accepted commits, including commits containing only previously accepted dirty work. Ask the user to commit accepted dirty work or discuss unreviewed changes as needed.
