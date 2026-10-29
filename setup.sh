#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Per-task agent state (ledgers, journals) is written by the agent, so it lives
# outside the workspace: Codex keeps .git and .agents inside it read-only.
export AGENT_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/agents"

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
merge_cleanup_hooks() {
  local path="$1"
  local cmd="$SCRIPT_DIR/hooks/cleanup-gate.sh"
  local tmp

  command -v jq >/dev/null || {
    echo "jq is required to merge cleanup hooks." >&2
    return 1
  }

  [[ -f "$path" ]] || echo '{}' > "$path"
  tmp="$(mktemp "${path}.XXXXXX")"
  jq --arg cmd "$cmd" '
    .hooks = (.hooks // {})
    | reduce ["SessionStart", "Stop"][] as $event (.;
        .hooks[$event] = (.hooks[$event] // [])
        | if ([.hooks[$event][].hooks[]?.command] | index($cmd)) then .
          else .hooks[$event] += [{matcher: "", hooks: [{type: "command", command: $cmd, timeout: 10}]}]
          end)
  ' "$path" > "$tmp"
  mv "$tmp" "$path"
}

grant_claude_state_dir() {
  local settings_path="$HOME/.claude/settings.json"
  local settings_tmp

  command -v jq >/dev/null || {
    echo "jq is required to grant the agent state directory to Claude Code." >&2
    return 1
  }

  [[ -f "$settings_path" ]] || echo '{}' > "$settings_path"
  settings_tmp="$(mktemp "$settings_path.XXXXXX")"
  jq '
    .permissions = (.permissions // {})
    | .permissions.additionalDirectories = ((.permissions.additionalDirectories // [])
        | if index(env.AGENT_STATE_DIR) then . else . + [env.AGENT_STATE_DIR] end)
  ' "$settings_path" > "$settings_tmp"
  mv "$settings_tmp" "$settings_path"
}

grant_codex_state_dir() {
  local config_path="$HOME/.codex/config.toml"
  local config_tmp

  yq --version 2>/dev/null | grep -q mikefarah || {
    echo "mikefarah/yq v4 is required to grant the agent state directory to Codex." >&2
    return 1
  }

  [[ -f "$config_path" ]] || : > "$config_path"
  # Skip present entries: a yq round trip reflows comments in multi-line arrays.
  [[ "$(yq -p toml -o yaml '.sandbox_workspace_write.writable_roots // [] | any_c(. == strenv(AGENT_STATE_DIR))' "$config_path")" == true ]] && return 0
  config_tmp="$(mktemp "$config_path.XXXXXX")"
  yq -p toml -o toml '.sandbox_workspace_write.writable_roots += [strenv(AGENT_STATE_DIR)]' "$config_path" > "$config_tmp"
  # The round trip can drop comments inside arrays; show the rewrite.
  diff -u "$config_path" "$config_tmp" >&2 || true
  mv "$config_tmp" "$config_path"
}

mkdir -p \
  "$AGENT_STATE_DIR" \
  "$HOME/.claude/skills" \
  "$HOME/.claude/commands" \
  "$HOME/.codex/rules" \
  "$HOME/.agents/skills"

ln -sfn "$SCRIPT_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
ln -sfn "$SCRIPT_DIR/AGENTS.md" "$HOME/.codex/AGENTS.md"
ln -sfn "$SCRIPT_DIR/settings/codex-deny.rules" "$HOME/.codex/rules/coding-prompts.rules"

merge_claude_deny_rules
merge_cleanup_hooks "$HOME/.claude/settings.json"
merge_cleanup_hooks "$HOME/.codex/hooks.json"
grant_claude_state_dir
grant_codex_state_dir

# Per-item symlinks so ~/.claude/{skills,commands} and ~/.agents/skills can
# co-host third-party tools (e.g. gstack) without polluting this repo.
# Claude Code reads ~/.claude/skills; Codex reads ~/.agents/skills.
for src in "$SCRIPT_DIR"/skills/*/; do
  name="$(basename "$src")"
  ln -sfn "$src" "$HOME/.claude/skills/$name"
  ln -sfn "$src" "$HOME/.agents/skills/$name"
done

# Portable snapshots of Claude Code built-ins, for Codex only
for src in "$SCRIPT_DIR"/skills/.portable/*/; do
  name="$(basename "$src")"
  ln -sfn "$src" "$HOME/.agents/skills/$name"
done

for src in "$SCRIPT_DIR"/commands/*; do
  [ -e "$src" ] || continue
  name="$(basename "$src")"
  ln -sfn "$src" "$HOME/.claude/commands/$name"
done
