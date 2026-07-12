#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands" "$HOME/.codex/skills"

ln -sfn "$SCRIPT_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
ln -sfn "$SCRIPT_DIR/AGENTS.md" "$HOME/.codex/prompts"

# Per-item symlinks so ~/.claude/{skills,commands} and ~/.codex/skills can
# co-host third-party tools (e.g. gstack) without polluting this repo.
for src in "$SCRIPT_DIR"/skills/*/; do
  name="$(basename "$src")"
  ln -sfn "$src" "$HOME/.claude/skills/$name"
  ln -sfn "$src" "$HOME/.codex/skills/$name"
done

for src in "$SCRIPT_DIR"/commands/*; do
  [ -e "$src" ] || continue
  name="$(basename "$src")"
  ln -sfn "$src" "$HOME/.claude/commands/$name"
done
