---
name: ship
description: "Ship the current branch as a PR: preflight, create with gh, run /cleanup, run a focused /code-review, then watch comments and CI and iterate. Squash-merges only with explicit per-PR approval."
---

# Ship

Authorizes creating the PR and working on follow-up fixes. Merging needs separate approval for this specific PR.

**Artifacts.** Write PR titles and bodies, review replies, merge messages, comments, docstrings, and documentation for readers without session context. Living artifacts state durable mechanisms, invariants, constraints, or tradeoffs; point-in-time evidence belongs in PR or commit prose. Every referent resolves from the repository, issue, or PR. Do not use session labels, unstored decisions, reassurance about non-changes, debate residue, or em dashes. Recheck artifacts against the final diff before merge.

Clean agents edit and verify explicitly assigned, non-overlapping local artifacts and behavior-preserving fixes directly without session rationale. The main agent handles conflicts, genuine ambiguity, design or public API decisions, and external publishing; it does not reimplement accepted changes.

GitHub renders bodies and comments as markdown, so keep each paragraph on one line and hard-wrap only inside fenced blocks and tables.

1. **Preflight.** `git status`, `git log origin/main..HEAD`, `gh pr list --head <branch> --state all`. Stop and ask (never resolve unilaterally) on a pre-existing dirty worktree, the default branch, divergence from remote (rebase/force-push is the user's call), or an existing merged/closed PR for this branch.

2. **PR.** `gh pr create`, or reuse the branch's existing **open** PR (`--state open`). Report the URL.

3. **Cleanup.** Run `/cleanup` on the branch diff. Repeat its artifact pass after later artifact changes.

4. **Background review**, launched after cleanup, parallel with step 5.
   - Clean `/code-review` agent carrying none of this session's context reports only material correctness, contract, test, compatibility, or misleading-artifact defects. Treat its findings as reviewer comments.
   - For non-trivial changes, challenge tests with decision-bearing and harmless mutations. Report tautologies, contract-breaking mutations that pass, and harmless mutations that fail. Do not report test style preferences.
   - Downstream sweep *only* if the repo documents external consumers **and** the diff breaks a published package's public surface: removal, rename, incompatible signature/type/schema, or documented behavior callers rely on. Additive, internal, or unreleased-flag changes don't qualify; unsure → ask. The agent greps consumer repos for the broken symbols (`gh search code --owner <org> "<symbol>"`, skip archived), folds confirmed impact into the PR body, and flags coordinated changes. Never edit consumer repos.

5. **Watch.** Block on `gh pr checks --watch`; re-read `gh pr view --comments` between events. Stop only when the agents have returned **and** required checks completed **and** every comment is fixed or answered. Green CI with zero comments means review hasn't run yet, not that you're done. Nothing ~15 min after CI settles → hand back. Fix only local, behavior-preserving feedback; anything touching design, public API, or intended behavior goes to the user first, even when the reviewer is right. Reply on the PR with reasoning when declining. Never wait on CI for work that hasn't reached the PR head.

6. **Merge (approval required).** Never merge while fixes sit uncommitted or unpushed; surface them instead. Otherwise ask: merge now, stage `--auto`, or don't. Squash with `--subject "<PR title> (#<num>)"` and a body drafted for the user first. Write it for `git log`, not the PR page: slim prose in the style of the repo's recent squash commits, what changed and why. No headers, bullets, bold, emoji, attribution, or test counts.

7. **Report.** URL, feedback addressed vs. declined, work left in the tree or unpushed, CI status, merge outcome, open judgment calls.
