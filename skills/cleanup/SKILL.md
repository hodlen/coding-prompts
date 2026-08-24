---
name: cleanup
description: "Pre-merge and mid-work guardrail: a clean agent checks the diff against the request, /simplify cleans what remains, then durable artifacts are scrubbed. Runs on an explicit target or as a standalone checkpoint."
---

# Cleanup

Use a supplied target; otherwise start at the latest `cleanup-reviewed-through: <short SHA>` in this task, promoting through later commits only when they contain only accepted dirty changes. Fall back to the remote-default fork point (`git merge-base --fork-point`, then `git merge-base`). Review commits plus staged, unstaged, and untracked changes; never persist checkpoints.

Passes A and C use a clean agent given only the diff, original request verbatim, plan file, and explicit constraints. Never inject prior agent output.

**A. Scope and constraints.** Check the diff against the request and every explicit constraint. Restore unnecessary touched files including formatting churn; remove unrequested features and tests or impossible-state guards; verify deletions by grep and GitHub bodies for mid-paragraph hard wraps. Apply mechanical fixes; report judgment calls.

**B. `/simplify`** on the same target; its review agents are already context-free.

**C. Durable artifacts.** Remove session-only references and point-in-time evidence; rewrite debate residue as durable mechanisms, invariants, constraints, or tradeoffs. Preserve meaning and report ambiguity. Skip mid-work when no durable artifacts exist.

Before returning, re-read HEAD and every dirty class. Cover user progress and cleanup's own edits observed then; if state moves again, report it unreviewed. End with:

`cleanup-reviewed-through: <short SHA>`

`cleanup-reviewed-dirty: staged=<accepted|none|unreviewed> unstaged=<...> untracked=<...>`

The main agent may advance through accepted commits, prompt the user to commit accepted dirty work, or discuss anything unreviewed.
