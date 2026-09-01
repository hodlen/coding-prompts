---
name: cleanup
description: "Pre-merge and mid-work guardrail: a clean agent checks the diff against the request, /simplify cleans what remains, then durable artifacts are scrubbed. Runs on an explicit target or as a standalone checkpoint."
---

# Cleanup

Use a supplied target. Otherwise compare the pushed frontier (the current branch's upstream tip, or the corresponding remote-tracking tip in a detached worktree) with the latest valid `cleanup-reviewed-through: <short SHA>` in this task and use the newer applicable commit. Treat pushed commits as stable. If neither exists, fall back to the remote-default fork point (`git merge-base --fork-point`, then `git merge-base`) as a last resort. Review the frontier-to-worktree diff, including unpushed commits and staged, unstaged, and untracked changes; never persist checkpoints.

Pass A uses a clean agent given only the diff, original request verbatim, plan file, and explicit constraints. Pass C uses a fresh clean agent given only the final diff, changed artifacts, and repository-visible references. Never inject prior agent output or session rationale. Clean agents edit and verify explicitly assigned, non-overlapping local scopes directly; return only conflicts or genuine ambiguity to the main agent.

**A. Scope and constraints.** Check the diff against the request and every explicit constraint. Audit changed tests against `Tests as contracts`: remove tautologies and mirrors, mock only IO seams, and mutation-check each design decision. Restore unnecessary touched files including formatting churn; remove unrequested features and tests or impossible-state guards; verify deletions by grep and GitHub bodies for mid-paragraph hard wraps. Apply mechanical fixes; report judgment calls.

**B. `/simplify`** on the same target; its review agents are already context-free.

**C. Durable artifacts.** Remove session-only references and point-in-time evidence; rewrite debate residue as durable mechanisms, invariants, constraints, or tradeoffs. Preserve meaning and report ambiguity. Skip mid-work when no durable artifacts exist.

Before returning, re-read HEAD and every dirty class. Cover user progress and cleanup's own edits observed then; if state moves again, report it unreviewed. End with:

`cleanup-reviewed-through: <short SHA>`

`cleanup-reviewed-dirty: staged=<accepted|none|unreviewed> unstaged=<...> untracked=<...>`

The main agent may advance through accepted commits, prompt the user to commit accepted dirty work, or discuss anything unreviewed.
