---
name: ship
description: Ship the current branch as a PR — verify branch is up to date with remote, create the PR with gh, launch a clean /code-review agent, then watch the PR for human/bot comments and iterate for 15 minutes. Can squash-merge (or stage an auto-merge) with the user's explicit per-PR approval.
---

# Ship

`/ship` is explicit authorization to push the branch, create the PR, and push follow-up fixes. Merging requires a separate explicit approval for this specific PR (step 5) — never merge without it.

1. **Preflight**: fetch and confirm the branch is up to date with its remote (push if only ahead; stop and report if dirty, behind, or diverged).
2. **PR**: create it with `gh pr create` (reuse the branch's existing PR if any). Report the URL immediately.
3. **Clean review**: launch a fresh background agent to run `/code-review` against the PR, so the review is unbiased by this session's context. Treat its findings like reviewer comments.
4. **Watch 15 min**: poll PR comments, reviews, and CI checks every ~2-3 minutes (automated review typically responds within 15 min). Fix valid feedback → commit, push, reply; reply with reasoning if not actionable. Stop early once all feedback is addressed and checks are green.
5. **Merge (with approval)**: once all feedback is addressed, ask the user (AskUserQuestion): merge now (CI green), stage auto-merge (`--auto`, CI pending), or don't merge. If approved: squash-merge with `--subject "<PR title> (#<num>)"` and a commit body written for `git log`, not the PR page — draft it for the user first. Slim flowing prose in the style of the repo's recent squash commits: headlines of what changed and why, no markdown headers/bullets/bold, no emoji or attribution footer, and no test counts or verification notes (CI on the merged commit is the record). Never GitHub's default commit-list body.
6. **Report**: PR URL, feedback addressed vs. rejected, CI status, merge outcome, anything needing the user's judgment.
