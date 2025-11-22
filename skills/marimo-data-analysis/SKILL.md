---
name: marimo-data-analysis
description: Reactive data analysis with Marimo. Use for Marimo notebooks and Python data analysis. Extends Python coding patterns.
---

# Marimo Notebook Patterns

## Core Constraints

- **Cell-wise reactivity upon args and return**: Every cell `return (vars,)` to export `vars`, and other cells can use it from args as `def _(vars, ...):`
- **Cell outputs matter:**: Same as Jupyter, last unassgined statement before return would be displayed
- **No duplicate variable names:** Marimo forbids reusing variable names across cells — use `_private` prefix for throwaway variables
- **No temp variables:** Chain all transformations—use `.pipe()`, `.assign()`, `.filter()`, not intermediate assignments
- **Pure functions:** Extract testable logic to separate modules
- **Mandatory testing:** Every notebook can run standalone: `python notebooks/some_notebook.py`
- **Imports and globals in setup:** All imports and global constants go in `with app.setup:` block, not in cells

## Data Loading

```python
with app.setup:
    import sys
    sys.path.append(".")
    from base_prelude import mo, pd, mo_sql

    # Heavy loads here - runs once, globally available
    full_blotter_df = mo_sql("SELECT * FROM inventory_blotter;", output=False)
```

Variables in `app.setup` are global—no need to pass as args. Put all non-reactive, zero-dependency imports/data here.

## Piping Everything

```python
# ✓ Pure pipeline - no intermediates
df
    .query("nature == 'equity'")
    .pipe(lambda x: x[x["units"].abs() > 0])  # Custom logic via pipe
    .assign(signed_units=lambda x: x["side"].map({"LONG": 1, "SHORT": -1}) * x["units"])
    .groupby(["date", "symbol"])
    .agg({"signed_units": "sum", "units": "count"})
    .pipe(lambda x: x[x["signed_units"].abs() > 1e-6])
    .reset_index()

# ✗ Temp variables cause name conflicts
temp1 = df.query("condition")  # Can't reuse 'temp1' elsewhere!
temp2 = temp1.groupby("key").sum()
result = temp2[temp2["value"] > 0]
```

**For view-only output (charts, tables, displays):** Just make the value the last statement without assignment.

```python
# ✓ Complex agg + chart as unnamed output
(
    df
    .groupby(["date", "strategy"])
    .agg({"pnl": "sum", "trades": "count"})
    .pipe(lambda x: alt.Chart(x.reset_index()).mark_bar().encode(
        x="date:T", y="pnl:Q", color="strategy:N"
    ))
)  # No variable name needed - auto-displays chart
```

## Pure Functions for Logic

```python
def is_valid_pair(df: pd.DataFrame) -> bool:
    """Pure, testable business logic"""
    return (
        len(df) == 2
        and df["units"].nunique() == 1
        and set(df["side"]) == {"LONG", "SHORT"}
    )

# Use in pipeline
violations = (
    df
    .groupby(["date", "symbol"])
    .filter(lambda x: not is_valid_pair(x))
    .pipe(lambda x: x if not x.empty else None)
)
```

Extract to `validation.py` for unit testing separate from notebook.

## Reactive UI

```python
# Cell 1: Control (returns UI widget)
date_picker = mo.ui.date_range(start="2025-10-01", stop=pd.Timestamp.now().date())
date_picker  # Display widget
return (date_picker,)

# Cell 2: Auto-reacts when picker changes
filtered = df.pipe(
    lambda x: x.query(f"date >= '{date_picker.value[0]}' and date <= '{date_picker.value[1]}'")
)
filtered
return (filtered,)
```

**Cell structure pattern:**
```python
@app.cell
def _(dep1, dep2):  # Dependencies as params
    result = compute(dep1, dep2)
    result  # Display (optional)
    return (result,)  # Export for other cells
```

## Master-Detail Pattern

```python
table_ui = mo.ui.table(summary_df, selection="single")

# Reactive detail view
detail = (
    full_df.query(f"symbol == '{table_ui.value.iloc[0]['symbol']}'")
    if not table_ui.value.empty else None
)
```

## Testing

Every notebook must be executable:
```bash
python notebooks/my_analysis.py  # Must pass without errors
```

Extract pure functions to modules:
```python
# validation.py
def check_trade_balance(df: pd.DataFrame) -> pd.DataFrame:
    """Returns unbalanced trades"""
    return df.groupby("trade_id").filter(lambda x: x["units"].sum().abs() > 1e-6)

# test_validation.py
def test_check_trade_balance():
    df = pd.DataFrame({"trade_id": [1, 1], "units": [100, -100]})
    assert check_trade_balance(df).empty
```

## Anti-Patterns

| Wrong | Right |
|-------|-------|
| `temp = df.query(...); result = temp.groupby(...)` | `result = df.query(...).groupby(...)` |
| `mo.md("text"); return` | `mo.md("text")` (last expression displays) |
| `try: result = transform(df) except: result = None` | `result = transform(df)  # Let it crash` |
| `for row in df.iterrows(): ...` | `.apply()`, `.pipe()`, vectorized ops |
| Duplicate variable names across cells | Unique names or `_private` prefix |
| `import pandas as pd` in cell | `with app.setup: import pandas as pd` |
| Excessive `if data is None` checks | Trust reactive dependencies |

## Quick Reference

```python
# Chain everything
df.query("...").assign(col=lambda x: ...).pipe(lambda x: ...).groupby(...).agg(...)

# Extract testable logic
.pipe(pure_function)
.groupby("key").filter(pure_predicate)

# Conditional rendering
result if condition else None
```
