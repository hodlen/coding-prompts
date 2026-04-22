---
name: python-patterns
description: Python-specific patterns and conventions. Assumes the general architecture/FP principles already apply.
---

# Python Patterns

## Typing

- Use modern syntax: `X | None`, `list[X]`, `dict[K, V]`. Avoid `Optional/Union/List/Dict`.
- Avoid `Any`. Use:
  - Pydantic models for runtime-validated structures.
  - `TypedDict` for lightweight internal dict shapes when runtime validation is unnecessary.
  - `object` only for opaque passthrough (must not be inspected).
- Prefer `from __future__ import annotations` in libraries to reduce runtime import coupling.

## Pydantic

- Use Pydantic for boundary models (HTTP, queue messages, config, DB row decoding where shape is not guaranteed).
- Keep validators narrow: shape, basic constraints, normalization. Do not embed workflow logic or IO in validators.
- Prefer explicit schema/versioning for externally consumed payloads (e.g., `v1`, `v2` modules or version fields).

## Pandas

- In new code, avoid `if df.empty:` unless a downstream operation requires non-empty input (e.g., `.min()`, `.max()`, `.iloc[0]`, single-row indexing). Otherwise, normalize DataFrame columns and types up front and let the pipeline handle empty DataFrames unconditionally.
- Avoid `df.col_name` and use `df["col_name"]` instead, rewriting when necessary. 

## Errors

- Catch exceptions only with a concrete recovery path; otherwise let them propagate.
- Avoid blanket handlers (`except Exception`) and silent fallbacks.
- For in-process compute failures with a meaningful branch, encode the failure in the return shape (dataclass, `Enum`, or tagged union via `Literal` discriminators). Reserve exceptions for truly exceptional or cross-layer infrastructure paths; when re-raising, add context.
- When a function has a meaningful degraded path (cache fallback, retry exhaustion, stale read), make it visible in the return shape — not hidden behind a success-looking return with side-channel signaling.

## Dependency and Resource Management

- Prefer function-shaped dependencies and explicit factories.
- For process-wide singletons, use `@functools.cache` on constructors when safe.

## Structure and Imports

- Organize code by domain; keep framework, router, and transport layers thin.
- Avoid re-exporting from `__init__.py` unless it materially improves the public module boundary.
- Do not use `utils/` as a catch-all. Create small, named modules with clear responsibility.
