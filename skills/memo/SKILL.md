---
name: memo
description: After a non-trivial task, audit the repo's CLAUDE.md (or AGENTS.md / equivalent) for gaps that cost time during the session. Add concise pointers, dedupe with sub-docs, prune stale entries. Goal: the next session onboards without rediscovering what you just learned.
---

# memo

Close the repo's discoverability loop. After a non-trivial task, ask: what did I have to grep, query, or guess that should have been one Read away? Update the repo's `CLAUDE.md` (or `AGENTS.md`) so the next session doesn't pay that cost again.

## When to invoke

- User asks ("update the guide", "memo this", "memo").
- Just finished a task that involved discovering a non-obvious helper, hitting a silent gotcha, choosing between docs to update, or hand-rolling a pattern that already existed.
- You noticed yourself wishing the guide had told you something.

Skip for typos and single-line fixes.

## Process

1. **List the friction points.** Things grepped for, helpers found mid-task, silent gotchas, choices that took thought.
2. **Read the current guide.** What's covered, what's missing.
3. **Add pointers, not content.** One row per doc / one bullet per helper or gotcha. Name the file or symbol; don't reproduce its docstring.
4. **Dedupe and prune.** Collapse sections that now repeat sub-docs back to a pointer. Drop entries for renamed/deleted code. No "history" sections — git log is the changelog.
5. **Bloat budget.** Treat the guide as a one-screen scan. Past ~80 lines, push content into a sub-doc and leave a pointer.
6. **Verify cold.** Re-read as if onboarding with no memory of the session. If a future agent would still grep around for what you grepped for, iterate. Optionally stress-test with a fresh subagent.

## What belongs where

- **In the guide:** pointers to canonical helpers (path + 1-line role), repo-wide naming conventions, silent gotchas, per-sub-doc summaries, lint/verification commands.
- **Not in the guide:** anything already obvious from `README.md` or well-named modules, long explanations, session narrative, multi-line code examples, rationale ("we chose X because Y" → sub-doc or commit).
- **Repo-wide idiom (2+ packages)** → root `CLAUDE.md`. **Package-specific surprise** → `<package>/CLAUDE.md`. **Detailed protocol / contract** → sub-doc under `<package>/docs/`, pointed at from the relevant `CLAUDE.md`.

## Anti-patterns

- "Recent changes" / "Session log" sections — it's not a journal.
- Copying a helper's docstring instead of pointing at the file.
- Entries that say "remember to do X" without saying *why* the obvious path is wrong — without the why, they rot.
- Growing the guide without ever pruning. Every addition should prompt: is something now redundant or stale?
