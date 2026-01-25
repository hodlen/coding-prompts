# Principles

## Architecture & Problem-solving

- Sanity-check the request against the current architecture first. Think in root-cause chains: **invariants → boundaries → effects → evidence**. Challenge patterns that hide decisions, defaults, or coupling.
- If the request exposes a structural flaw, propose a **small, concrete refactor** (tight scope, clear payoff) before adding features.
- Prefer **minimal, local changes** over rewrites, but do not preserve bad boundaries “because it exists”.
- Keep designs explicit and inspectable: data flow, dependencies, and contracts (inputs/outputs) must be visible, versionable, and testable.
- Separate concerns by responsibility (semantic separation ≠ physical separation): you may pipeline/stream/cache for performance, but the **decision points and boundaries must remain explicit**.
- Treat “what changes the result” as first-class: make policies/defaults/thresholds/version pins explicit and carry them through the flow.

## FP: Purity, Effects, Composition, DRY

- Favor **pure functions** and immutable state. Model workflows as transformations with explicit inputs/outputs.
- Push side effects (IO, persistence, logging, framework glue) to the edges via **explicit dependency injection** (pass the required function shapes, not heavy interfaces).
- Keep control flow structural: represent expected failure and branching as return values (e.g., `Result`/`Either`/ADTs), not ad-hoc exceptions.
- Maintain a **single source of truth**: no shadow state, duplicated derivations, or parallel configs. Prefer one canonical representation + projections.
- Preserve composability: small total functions, explicit types, no hidden global context.

## Domain modeling & Contracts (Transactional + Analytics)

- Model constraints at construction: use smart constructors / `create` to ensure “trusted domain values”; once created, avoid repeated defensive checks.
- Make illegal states unrepresentable with types (ADTs/state machines) where it reduces systemic bugs.
- Define clear boundaries:
  - Transactional: aggregates and consistency/transaction boundaries.
  - Data/analytics: dataset/contract boundaries (keys/time semantics, alignment/join rules, schema hashes), not row-level over-modeling.
- Cross-boundary interaction must go through explicit contracts (DTOs/events/artifact references + translation/ACL). Never leak internal models.

## Evidence & Reproducibility (as a default quality bar)

- Any decision that affects outcomes must be **replayable**: serialize/hash the plan/policy/config that drove it; record input references and output checksums.
- Prefer “gate/validate/create” stages that yield either:
  - a **validated, compute-consumable** value (with evidence), or
  - a **structured refusal** (with reasons and actionable hints).
- Do not bury decisions inside IO helpers or clients. “Tagging the result” is not sufficient if it cannot reproduce the decision path.

## Readability, docs, and comments

- Code must be readable without comments: clear names, clear signatures, clear types.
- Comments only for non-obvious tradeoffs, invariants, constraints, or domain reasoning.
- Do not write changelog-style or historical comments.
- Runtime explanations belong in **structured logging** (`logger.debug/info`) and emitted at the boundary where the branch is chosen.

## Errors and safety

- Fail fast and loudly. No empty catch/except blocks, no defensive noise.
- Add error handling only when there is a concrete recovery path. Otherwise, surface a precise failure with context.

## Terminal and scripts

- For one-off tasks, prefer short, composable shell pipelines. Avoid large throwaway scripts.
- For repeatable workflows, extract scripts (`scripts/` or `package.json`/`pyproject.toml` inline scripts).

## Project notes

- If `CLAUDE.md` (or `AGENT.md`) exists, read it first and follow its conventions.
- When changing core data flow, architecture, or module boundaries, propose an update to that file.

## Tool use

- Prefer `pnpm` over `npm`, and `pnpm dlx` over `npx`.
- On `command not found`:
  - For Python tools: check project venv (e.g., `.venv/`), else global venv (e.g., `~/.venvs/base`), activate and retry.
  - For missing binaries/packages: stop and ask the user. Do not install anything globally.
