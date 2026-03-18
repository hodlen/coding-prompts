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

- Avoid any `if df.empty:` for new code. Instead, normalize DataFrame columns and types when appropriate, and handle empty DataFrames unconditionally.
- Avoid `df.col_name` and use `df["col_name"]` instead, rewriting when necessary. 

## Errors

- Catch exceptions only with a concrete recovery path; otherwise let them propagate.
- Avoid blanket handlers (`except Exception`) and silent fallbacks.
- Use structured, typed errors for expected failure modes (dataclasses/Enums). Add context when re-raising infrastructure errors.

## Dependency and Resource Management

- Prefer function-shaped dependencies and explicit factories.
- For process-wide singletons, use `@functools.cache` on constructors when safe.

## Structure and Imports

- Organize code by domain; keep framework, router, and transport layers thin.
- Avoid re-exporting from `__init__.py` unless it materially improves the public module boundary.
- Do not use `utils/` as a catch-all. Create small, named modules with clear responsibility.
