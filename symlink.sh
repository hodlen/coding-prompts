#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$HOME/.claude"
ln -sfn "$SCRIPT_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
ln -sfn "$SCRIPT_DIR/skills" "$HOME/.claude/skills"

mkdir -p "$HOME/.codex"
ln -sfn "$SCRIPT_DIR/AGENTS.md" "$HOME/.codex/prompts"
ln -sfn "$SCRIPT_DIR/skills" "$HOME/.codex/skills"
