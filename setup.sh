#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

merge_claude_deny_rules() {
  local settings_path="$HOME/.claude/settings.json"
  local settings_tmp

  command -v jq >/dev/null || {
    echo "jq is required to merge Claude Code permissions." >&2
    return 1
  }

  settings_tmp="$(mktemp "$HOME/.claude/settings.json.XXXXXX")"
  if [[ -f "$settings_path" ]]; then
    jq --slurpfile deny "$SCRIPT_DIR/settings/claude-deny.json" '
      (.permissions.deny // []) as $existing
      | if ($existing | type) != "array" then
          error("permissions.deny must be an array")
        else
          .permissions = (.permissions // {})
          | .permissions.deny = reduce $deny[0][] as $rule
              ($existing; if index($rule) then . else . + [$rule] end)
        end
    ' "$settings_path" > "$settings_tmp"
  else
    jq -n --slurpfile deny "$SCRIPT_DIR/settings/claude-deny.json" \
      '{permissions: {deny: $deny[0]}}' > "$settings_tmp"
  fi
  mv "$settings_tmp" "$settings_path"
}

# Same hook schema on both sides: Claude Code reads hooks from settings.json,
# Codex from hooks.json. Dedup by command path so re-runs are no-ops.
merge_stop_hook() {
  local path="$1"
  local cmd="$SCRIPT_DIR/hooks/cleanup-gate.sh"
  local tmp

  command -v jq >/dev/null || {
    echo "jq is required to merge Stop hooks." >&2
    return 1
  }

  [[ -f "$path" ]] || echo '{}' > "$path"
  tmp="$(mktemp "${path}.XXXXXX")"
  jq --arg cmd "$cmd" '
    .hooks = (.hooks // {})
    | .hooks.Stop = (.hooks.Stop // [])
    | if ([.hooks.Stop[].hooks[]?.command] | index($cmd)) then .
      else .hooks.Stop += [{matcher: "", hooks: [{type: "command", command: $cmd, timeout: 10}]}]
      end
  ' "$path" > "$tmp"
  mv "$tmp" "$path"
}

mkdir -p \
  "$HOME/.claude/skills" \
  "$HOME/.claude/commands" \
  "$HOME/.codex/rules" \
  "$HOME/.agents/skills"

ln -sfn "$SCRIPT_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
ln -sfn "$SCRIPT_DIR/AGENTS.md" "$HOME/.codex/AGENTS.md"
ln -sfn "$SCRIPT_DIR/settings/codex-deny.rules" "$HOME/.codex/rules/coding-prompts.rules"

merge_claude_deny_rules
merge_stop_hook "$HOME/.claude/settings.json"
merge_stop_hook "$HOME/.codex/hooks.json"

# Per-item symlinks so ~/.claude/{skills,commands} and ~/.agents/skills can
# co-host third-party tools (e.g. gstack) without polluting this repo.
for src in "$SCRIPT_DIR"/skills/*/; do
  name="$(basename "$src")"
  ln -sfn "$src" "$HOME/.claude/skills/$name"
  ln -sfn "$src" "$HOME/.agents/skills/$name"
done

for src in "$SCRIPT_DIR"/commands/*; do
  [ -e "$src" ] || continue
  name="$(basename "$src")"
  ln -sfn "$src" "$HOME/.claude/commands/$name"
done

# Claude Code ships /simplify and /code-review as built-ins (in-binary, no
# files to link). Codex has neither, so link portable snapshots into
# ~/.codex/skills only: ~/.agents/skills would shadow the richer built-ins,
# because Claude Code reads that directory too.
mkdir -p "$HOME/.codex/skills"
for src in "$SCRIPT_DIR"/skills/.portable/*/; do
  name="$(basename "$src")"
  [ -e "$HOME/.codex/skills/$name" ] || ln -sfn "$src" "$HOME/.codex/skills/$name"
done
