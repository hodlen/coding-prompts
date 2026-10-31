---
name: python-patterns
description: Python-specific compatibility, pandas, and cached-resource lifetime caveats.
---

# Python Patterns

- For Python 3.12+ projects using PEP 695, prefer inline generics over new `TypeVar`/`Generic` scaffolding.
- Use `@functools.cache` on resource constructors only when shared lifetime and cleanup semantics are safe.

## Pandas Patterns
- pandas merges match null keys to each other. `validate=` checks key cardinality, not match completeness; use it for required cardinality not already guaranteed. `indicator=True` can expose unmatched rows when completeness matters.
- pandas arithmetic and assignment align on index labels. Establish whether the operation needs label or positional alignment; preserve meaningful labels and resolve unintended misalignment.
- `groupby` drops null group keys by default; use `dropna=False` when those rows belong in the result.
- Normalize columns and types so pandas pipelines accept empty DataFrames. Guard `df.empty` only before operations requiring rows, such as `.iloc[0]`.
- Refer to `data-engineering` for rules on keys, grain, joins, time, schema, ordering and aggregation.
