---
name: cleanup
description: "Pre-merge and mid-work guardrail: a clean agent checks the diff against the request, /simplify cleans what remains, then durable artifacts are scrubbed. Runs on an explicit target or as a standalone checkpoint."
---

# Cleanup

Capture HEAD before review. Use a supplied target; otherwise use the latest plain-text `cleanup-reviewed-through: <SHA>` from this task when it lies between the remote-default fork point and captured HEAD, falling back to that fork point (`git merge-base --fork-point`, then `git merge-base`). Review through captured HEAD plus staged, unstaged, and untracked changes. Checkpoints cover commits only; never persist them.

Passes A and C use a clean agent given only the diff, original request verbatim, plan file, and explicit constraints. Never inject prior agent output.

**A. Scope and constraints.** Check the diff against the request and every explicit constraint. Restore unnecessary touched files including formatting churn; remove unrequested features and tests or impossible-state guards; verify deletions by grep and GitHub bodies for mid-paragraph hard wraps. Apply mechanical fixes; report judgment calls.

**B. `/simplify`** on the same target; its review agents are already context-free.

**C. Durable artifacts.** Remove session-only references and point-in-time evidence; rewrite debate residue as durable mechanisms, invariants, constraints, or tradeoffs. Preserve meaning and report ambiguity. Skip mid-work when no durable artifacts exist.

After all passes, end the response with plain text `cleanup-reviewed-through: <captured SHA>`.
