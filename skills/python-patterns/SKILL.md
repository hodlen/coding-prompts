---
name: python-patterns
description: Python-specific patterns and conventions. Assumes the general architecture/FP principles already apply.
---

# Python Patterns

## Typing

- Use modern syntax supported by the project's Python target: `X | None`, `list[X]`, `dict[K, V]`.
- For Python 3.12+ codebases that use it, prefer PEP 695 inline generics over new `TypeVar`/`Generic[T]` boilerplate. Follow the repository's established style in existing modules.
- Prefer precise types over `Any`. Use runtime-validated models at untrusted boundaries, `TypedDict` for lightweight internal mappings, and `object` for genuinely opaque passthrough. Keep `Any` only where the dynamic contract cannot be expressed credibly, and contain it at the boundary.

## Runtime Validation

- Use the repository's established validation library for untrusted boundary models such as HTTP payloads, queue messages, configuration, and DB rows whose shape is not guaranteed. In Pydantic codebases, use Pydantic for that role.
- Keep validators narrow: shape, basic constraints, normalization. Do not embed workflow logic or IO in validators.
- Prefer explicit schema/versioning for externally consumed payloads (e.g., `v1`, `v2` modules or version fields).

## Pandas

- In new code, avoid `if df.empty:` unless a downstream operation requires non-empty input (e.g., `.min()`, `.max()`, `.iloc[0]`, single-row indexing). Otherwise, normalize DataFrame columns and types up front and let the pipeline handle empty DataFrames unconditionally.
- Avoid `df.col_name` and use `df["col_name"]` instead, rewriting when necessary.

## Errors

- Catch exceptions only with a concrete recovery path; otherwise let them propagate.
- Avoid blanket handlers (`except Exception`) and silent fallbacks.
- For in-process compute failures with a meaningful branch, encode the failure in the return shape (dataclass, `Enum`, or tagged union via `Literal` discriminators). Reserve exceptions for truly exceptional or cross-layer infrastructure paths; when re-raising, add context.
- When a function has a meaningful degraded path (cache fallback, retry exhaustion, stale read), make it visible in the return shape, not hidden behind a success-looking return with side-channel signaling.

## Dependency and Resource Management

- Prefer function-shaped dependencies and explicit factories.
- Construct process-wide resources at the composition edge. Use `@functools.cache` on constructors only when shared lifetime and cleanup semantics are safe.

## Structure and Imports

- Organize code by domain; keep framework, router, and transport layers thin.
- Avoid re-exporting from `__init__.py` unless it materially improves the public module boundary.
- Do not use `utils/` as a catch-all. Create small, named modules with clear responsibility.

## Docstrings and Comments

The general "no comments unless the WHY is non-obvious" rule applies. Python-specific corollaries:

- **Decision rule.** Delete the docstring mentally. If the reader only loses information already in the name and types, delete it for real. If the reader loses a constraint the caller must know, keep it, and rewrite it so it says *just that constraint*.
- **Default by visibility.** Public, non-trivial functions may need a one-line semantic summary, plus a short body only when there is a real contract such as PIT semantics, idempotency, atomicity, ordering, caller invariants, version-specific workarounds, or failure modes the type does not imply. Private and trivial functions usually need no docstring.
- **Prefer prose-with-WHY over Google-style blocks.** Reach for `Args:`/`Returns:`/`Yields:`/`Raises:` only when the type/name can't express the constraint, and write *just that constraint*, not a paraphrase of the parameter name. `Examples:` only when the usage pattern is non-obvious.
- **Dataclass/Pydantic field docs** follow the same rule: drop `key: Document key within the topic`; keep `must be timezone-aware`.
- **Delete on sight:** `Args:` blocks that restate the param name, `Returns:` blocks that restate the type, class docstrings paraphrasing the class name (`"""User class."""`), and comments narrating the next line (`# increment counter`).
- **Inline comments** follow the same WHY-only rule, more strictly. Reserve them for library footguns (`# argMax skips NULLs silently`), invariants being relied on, or workarounds whose reason isn't visible. Never write changelog comments (`# replaced by X`), because git history is the changelog.
