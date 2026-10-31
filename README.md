# agents

Personal instructions, skills, and hooks for Codex and Claude Code, built around explicit contracts and evidence-based review.

## Install

Requires Git and [uv](https://docs.astral.sh/uv/).

```sh
git clone https://github.com/hodlen/agents.git
cd agents
./install.py
```

The installer links instructions and skills, merges user settings and hooks, and installs `crapper`, `dryer`, and `mutator` for code analysis. Keep the checkout in place because the installed links point to it.

## Contents

- [AGENTS.md](AGENTS.md): shared coding principles and workflow.
- [skills/](skills/): review, cleanup, simplification, and language-specific guidance.
- [hooks/](hooks/) and [settings/](settings/): cleanup checks and agent permissions.

## Skills

| Skill | Purpose |
| --- | --- |
| [html-plan](skills/html-plan/SKILL.md) | Build an interactive implementation plan with concrete examples and decisions to review. |
| [simplify](skills/simplify/SKILL.md) | Improve reuse, clarity, efficiency, and ownership while preserving behavior. |
| [code-review](skills/.portable/code-review/SKILL.md) | Find and verify defects in correctness, contracts, tests, compatibility, and documentation. |
| [cleanup](skills/cleanup/SKILL.md) | Check scope and contracts, simplify changes, and clean up durable artifacts before delivery or at a checkpoint. |
| [ship](skills/ship/SKILL.md) | Create or continue a PR, run reviews, and resolve feedback and CI; merge only with approval. |
| [python-patterns](skills/python-patterns/SKILL.md) | Handle Python compatibility, cached resource lifetimes, and pandas behavior. |
| [marimo-patterns](skills/marimo-patterns/SKILL.md) | Keep Marimo cell dependencies, state, display, and notebook execution correct. |
| [data-engineering](skills/data-engineering/SKILL.md) | Preserve data meaning across joins, time handling, conversions, aggregation, and reruns. |
