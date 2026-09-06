---
name: marimo-data-analysis
description: Marimo-specific notebook authoring and debugging for reactive cell boundaries, private and exported symbols, single-cell outputs, UI dependencies, and standalone execution. Use whenever reading, writing, fixing, or reviewing a Marimo `.py` notebook. Load alongside `python-patterns` for Python conventions.
---

# Marimo Notebook Patterns

## Model the reactive graph

Marimo executes cells from name dependencies, not page order. Treat every cross-cell name as a graph edge.

- Define each public top-level name in exactly one cell.
- Each cell parameter comes from one upstream export or setup. Return only public names needed downstream, assigned on every execution path.
- Prefix cell-local values with `_`. These names may repeat across cells but cannot be dependencies. Give downstream values descriptive public names and export them.
- Use cells for meaningful reactive stages such as control, transform, and presentation, avoiding one cell per statement or a single cell for the notebook.

Keep local work private and expose the smallest meaningful result:

```python
@app.cell
def _(summarize_positions, trades_df):
    _active = trades_df.loc[trades_df["status"].eq("active")]
    position_summary_df = summarize_positions(_active)
    return (position_summary_df,)
```

## Produce one unconditional output

Give presentation cells exactly one unconditional final unassigned expression, immediately before the generated return. Compute branch results first and use `_output` for view-only values:

```python
@app.cell
def _(mo, render_detail, selection_df):
    _output = (
        mo.md("Select a row")
        if selection_df.empty
        else render_detail(selection_df)
    )
    _output
    return
```

Combine multiple visible objects with `mo.vstack`, `mo.hstack`, or another layout and display it once.

For a cell that both displays and exports:

```python
@app.cell
def _(build_summary, source_df):
    summary_df = build_summary(source_df)
    summary_df
    return (summary_df,)
```

## Keep controls and views reactive

- Export a UI control from the cell that creates it. A downstream cell reading `.value` must accept that control as a dependency.
- Model empty selections, unset controls, and other expected UI states as a placeholder or real view through the single-output pattern.

## Keep logic modular and cells idempotent

- Put reusable or non-trivial compute in pure functions, preferably in importable Python modules.
- Keep imports in ordinary cells by default. Use `with app.setup:` only for symbols that must exist before top-level function or class declarations; setup cannot depend on regular cells.
- Mutate objects only in the cell that creates them; downstream cells return new values so Marimo observes the dependency.
- Keep IO at explicit edge cells. Given the same dependencies, compute and presentation cells should produce the same result.
- Let unexpected failures surface instead of hiding broad exceptions. Make expected missing or degraded states visible in the value or rendered output.

## Validate the notebook

For completion, execute the full reactive program in the repository environment:

```bash
python notebooks/my_analysis.py
```

The run must succeed without interactive state. During the staged review pauses under `Top-down implementation` in the general instructions, explicit stub failures are expected; identify them separately from reactive-graph errors. Before completion, resolve both. Also run `marimo check <notebook.py>` when available and unit-test extracted compute with the repository's test runner. Inspect the graph, exports, and output rules above, including paths execution did not cover.
