# Principles

## Architecture & Problem-solving

- Start by sanity-checking the request against the existing codebase / structure. Think in terms of root causes, invariants, and architectural fit. Challenge weak patterns.
- If the request exposes a structural issue, propose a small, concrete refactor before implementing.
- Prefer **minimal, local changes** that fit current architecture over large rewrites.
- Keep designs explicit: data flow, dependencies, inputs/outputs must be visible and controlled.

## FP, Immutability, DRY
- Favor pure functions, immutable state, and clear data transformations.
- Push side effects (IO, persistence, logging, framework glue) to the edges.
- Maintain a single source of truth. Avoid shadow state, duplication, or parallel configs.

## Readability, docs and comments

- Code must be readable without comments: clear names, clear signatures, clear types.
- Comments are only for non-obvious tradeoffs, invariants, constraints or domain reasoning.
- Do **not** write changelog-style comments or historical notes (e.g. "replaced by X", "moved to Y").
- Explanations tied to runtime behavior (exceptional/failsafe branches taken, unusual states) belong in structured logging (`logger.debug/info`), **not** in comments.

## Readability, docs and comments

- Code must be readable without comments: clear names, clear signatures, clear types.
- Comments are only for non-obvious tradeoffs, gotchas and invariants.
- Do **not** write changelog-style comments and or historical notes (e.g. "replaced by X", "moved to Y"). Docs describe the current behavior, not its history.

## Errors and safety

- Crash fast and loudly. No empty catch/except blocks, no defensive noise.
- Add error handling only when there is a concrete recovery path.

## Terminal and scripts

- For one-off tasks, prefer short, composable shell pipelines. Avoid large, one-shot throwaway scripts.
- For repeatable workflows, extract scripts (`scripts/` or `package.json`/`pyproject.toml` inline scripts).

## Project notes

- If `CLAUDE.md` (or `AGENT.md`) exists, read it first and follow its conventions.
- When changing core data flow, project artechitecture or module boundaries, propose an update to that file.

# Tool use

- Prefer `pnpm` over `npm`, and `pnpm dlx` over `npx`.
- On `command not found`:
  - For Python tools: first check for project venv (e.g. `.venv/`), if not found, check global venv (e.g. `~/.venvs/base`), then activate and retry.
  - For missing binaries / packages: stop and ask the user. **Do not** install anything globally.
