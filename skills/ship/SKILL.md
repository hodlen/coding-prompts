---
name: ship
description: Ship the current branch as a PR — preflight, create with gh, run a clean /code-review, then watch comments and CI and iterate. Squash-merges only with explicit per-PR approval.
---

# Ship

Authorizes creating the PR and pushing follow-up fixes. Merging needs separate approval for this specific PR.

**Constraint.** Use git for reads only (`fetch`, `status`, `log`); route every remote mutation through `gh`. If a step needs a push you can't make, report it and hand back — don't work around it.

1. **Preflight.** `git fetch -v`, `git status`, `git log origin/main..HEAD`, `gh pr list --head <branch> --state all`. Stop and ask — never resolve unilaterally — on a dirty worktree, the default branch, divergence from remote (rebase/force-push is the user's call), or an existing merged/closed PR for this branch.

2. **PR.** `gh pr create`, or reuse the branch's existing **open** PR (`--state open`). Report the URL.

3. **Background reviews**, both launched now, parallel with step 4.
   - Clean `/code-review` agent carrying none of this session's context; treat its findings as reviewer comments.
   - Downstream sweep *only* if the repo documents external consumers **and** the diff breaks a published package's public surface — removal, rename, incompatible signature/type/schema, or documented behavior callers rely on. Additive, internal, or unreleased-flag changes don't qualify; unsure → ask. The agent greps consumer repos for the broken symbols (`gh search code --owner <org> "<symbol>"`, skip archived), folds confirmed impact into the PR body, and flags coordinated changes. Never edit consumer repos.

4. **Watch.** Block on `gh pr checks --watch`; re-read `gh pr view --comments` between events. Stop only when the agents have returned **and** required checks completed **and** every comment is fixed or answered — green CI with zero comments means review hasn't run yet, not that you're done. Nothing ~15 min after CI settles → hand back. Fix only local, behavior-preserving feedback; anything touching design, public API, or intended behavior goes to the user first, even when the reviewer is right. Reply on the PR with reasoning when declining.

5. **Merge (approval required).** Ask: merge now, stage `--auto`, or don't. Squash with `--subject "<PR title> (#<num>)"` and a body drafted for the user first. Write it for `git log`, not the PR page: slim prose in the style of the repo's recent squash commits, what changed and why. No headers, bullets, bold, emoji, attribution, or test counts. Never GitHub's default commit list.

6. **Report.** URL, feedback addressed vs. declined, CI status, merge outcome, open judgment calls.
