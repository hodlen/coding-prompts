---
name: python-patterns
description: Python-specific compatibility, pandas, and cached-resource lifetime caveats.
---

# Python Patterns

- For Python 3.12+ projects using PEP 695, prefer inline generics over new `TypeVar`/`Generic` scaffolding.
- Use `df["column"]` for pandas column access instead of `df.column`.
- Normalize columns and types so pandas pipelines accept empty DataFrames. Guard `df.empty` only before operations requiring rows, such as `.iloc[0]`.
- Use `@functools.cache` on resource constructors only when shared lifetime and cleanup semantics are safe.
