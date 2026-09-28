---
name: ship
description: "Create or continue a PR, run cleanup and code review, and resolve feedback and CI. Squash-merge only with approval for that PR."
---

# Ship

Authorizes creating the PR and working on follow-up fixes. Merging needs separate approval for this specific PR.

Apply `Durable artifacts` from the general instructions and supply that policy to artifact workers. Recheck artifacts against the final diff before merge.

Assign clean agents non-overlapping local scopes to edit and verify, without session rationale. The main agent handles conflicts, ambiguity, design or public API decisions, and external publishing without reimplementing accepted fixes.

Keep GitHub paragraphs on one line; hard-wrap only fenced blocks and tables.

1. **Preflight.** `git status`, `git log origin/main..HEAD`, `gh pr list --head <branch> --state all`. Require the completion stage: reviews approved or explicitly waived, stubs implemented, and verification run or limitations reported. Stop and ask on a pre-existing dirty worktree, the default branch, remote divergence, or a merged/closed PR for this branch; rebasing and force-pushing remain the user's decision.

2. **PR.** `gh pr create`, or reuse the branch's existing **open** PR (`--state open`). Report the URL. The body states what the diff shows; claims about jobs, consumers, or data follow the check that supports them.

3. **Cleanup.** Run `/cleanup` on the branch diff. Repeat its artifact pass after later artifact changes.

4. **Background review**, launched after cleanup, parallel with step 5.
   - Give one clean `/code-review` agent the diff, explicit constraints, completion stage, and the remaining mutation scope under `Tests as contracts`. Treat its findings as reviewer comments: judge each against the request and repository (a wording finding gets a wording fix), and produce the concrete failing case before relaying one to the user; relay unverified only when verification needs data you cannot reach.
   - Sweep downstream only when the repository documents external consumers and the diff breaks a published package's public surface (removal, rename, incompatible signature, type, or schema, changed documented behavior); ask if eligibility is uncertain. Search broken symbols in non-archived consumer repos  (`gh search code --owner <org> "<symbol>"`), report confirmed impact in the PR body, and flag coordination needs without editing consumer repos.

5. **Checks and feedback.** Snapshot `gh pr checks` and `gh pr view --comments` when `/ship` starts and whenever the user reports a push (pushes are the user's). Where the host supports background commands with completion notification, watch in the background. Fix local, behavior-preserving feedback; take design, public API, or behavior changes to the user first. Recheck decisions affected by later fixes under `Tests as contracts`. Explain declined feedback on the PR.

6. **Merge (approval required).** Never merge, or arm `--auto`, while fixes sit uncommitted or unpushed or a verified reviewer finding is open; surface them instead. Otherwise ask: merge now, stage `--auto`, or don't. Squash with `--subject "<PR title> (#<num>)"` and a body drafted for the user first. Write it for `git log`, not the PR page: slim prose in the style of the repo's recent squash commits. No headers, bullets, bold, emoji, attribution, or test counts.

7. **Report.** URL, feedback addressed vs. declined, work left in the tree or unpushed, CI status, merge outcome, open judgment calls.
