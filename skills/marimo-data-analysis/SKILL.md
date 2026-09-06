---
name: marimo-data-analysis
description: Reactive graph, display, setup, and execution caveats for reading or editing Marimo notebooks. Use alongside python-patterns.
---

# Marimo Notebook Patterns

## Reactive graph

- Cells execute by name dependencies, not page order. Define each public name in one cell; cell parameters must resolve to an upstream export or setup.
- Prefix cell-local names with `_`; they may repeat across cells but cannot be dependencies. Return only public values needed downstream, assigned on every path.
- Use cell boundaries for meaningful reactive stages such as controls, transformations, and views.
- Mutate objects only in their creation cell; downstream cells return new values so Marimo observes the dependency.
- Export UI controls from their creation cell. Consumers reading `.value` must depend on the control.
- Keep imports in ordinary cells. Use `with app.setup:` only for symbols needed before top-level function or class declarations; setup cannot depend on regular cells.

## Display

Give presentation cells one unconditional final unassigned expression, immediately before the generated return. Use conditional expressions directly for simple empty or unset UI states. Combine multiple visible objects with `mo.vstack`, `mo.hstack`, or another layout and display once.

```python
@app.cell
def _(build_summary, mo, source_df):
    summary_df = build_summary(source_df)
    mo.md("No rows") if summary_df.empty else summary_df
    return (summary_df,)
```

## Verification

At completion, require `python <notebook.py>` to succeed without interactive state in the repository environment. Also run `marimo check <notebook.py>` when available. Inspect dependencies, exports, and outputs on paths execution did not cover.
