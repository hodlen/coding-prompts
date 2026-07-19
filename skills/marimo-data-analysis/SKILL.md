---
name: marimo-data-analysis
description: Marimo-specific notebook authoring and debugging for reactive cell boundaries, private and exported symbols, single-cell outputs, UI dependencies, and standalone execution. Use whenever reading, writing, fixing, or reviewing a Marimo `.py` notebook. Load alongside `python-patterns` for Python conventions.
---

# Marimo Notebook Patterns

## Model the reactive graph

Marimo executes cells from name dependencies, not page order. Treat every cross-cell name as a graph edge.

- Define each public top-level name in exactly one cell.
- Receive upstream public names as cell parameters. Return only public names needed downstream.
- Prefix cell-local values with `_`. Private names may repeat across cells, but another cell cannot depend on them.
- If a private value is needed downstream, give it a descriptive public name and export it deliberately.
- Use cell boundaries for meaningful reactive stages such as control, transform, and presentation. Do not make every statement a cell or put the whole notebook in one cell.

Keep local work private and expose the smallest meaningful result:

```python
@app.cell
def _(trades_df):
    _active = trades_df.loc[trades_df["status"].eq("active")]
    position_summary_df = summarize_positions(_active)
    return (position_summary_df,)
```

## Produce one unconditional output

A cell displays its final unassigned expression. Give a presentation cell exactly one unconditional final output expression.

Do not leave display expressions inside `if`/`else` branches. Compute the branch result, then display it once:

```python
@app.cell
def _(mo, selection_df):
    _output = (
        mo.md("Select a row")
        if selection_df.empty
        else render_detail(selection_df)
    )
    _output
    return
```

Assign exported values on every execution path; never define a public name only inside one branch. For multiple visible objects, combine them with `mo.vstack`, `mo.hstack`, or another layout and display the layout once.

When a cell both displays and exports a value, put the display expression immediately before the generated return:

```python
@app.cell
def _(source_df):
    summary_df = build_summary(source_df)
    summary_df
    return (summary_df,)
```

Use `_output` for view-only values so presentation details do not become graph edges.

## Keep controls and views reactive

- Export a UI control from the cell that creates it. A downstream cell reading `.value` must accept that control as a dependency.
- Model empty selections, unset controls, and other expected UI states explicitly.
- Produce one placeholder or one real view through the single-output pattern. Do not hide broad exceptions or rely on branch-local displays.

## Keep logic modular and cells idempotent

- Put reusable or non-trivial compute in pure functions, preferably in ordinary Python modules that unit tests can import.
- Keep imports in ordinary cells by default. Use `with app.setup:` only for symbols that must exist before top-level function or class declarations; setup cannot depend on regular cells.
- Do not mutate an object in a different cell from the one that creates it. Return a new value so Marimo can observe the dependency.
- Keep IO at explicit edge cells. Given the same dependencies, compute and presentation cells should produce the same result.
- Let unexpected failures surface. Make expected missing or degraded states visible in the value or rendered output.

## Validate the notebook

After editing, execute the full reactive program in the repository environment:

```bash
python notebooks/my_analysis.py
```

The dry run must exit successfully. It catches incorrect cell parameters, missing exports, duplicate definitions, setup-reference errors, and failures hidden by interactive state. Also run `marimo check <notebook.py>` when available, and unit-test extracted compute with the repository's normal test runner.

Before finishing, verify:

- every cell parameter comes from exactly one upstream export or setup
- every downstream value is public and returned; every temporary value is private
- every presentation cell has one unconditional final output expression
- every exported name is assigned on every path
- `python <notebook.py>` passes
