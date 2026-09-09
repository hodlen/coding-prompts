#!/usr/bin/env bash
# SessionStart captures pre-edit state; Stop blocks after many lines since the
# last cleanup pass. Baseline and re-arm come from host-written facts (git
# objects, transcript records), never from markers the model types.
set -euo pipefail

THRESHOLD_LINES=${CLEANUP_GATE_LINES:-400}
INTERVAL_SECS=${CLEANUP_GATE_SECS:-3600}
STATE_TTL_DAYS=14

input=$(cat)
[[ "$input" == *'"stop_hook_active":true'* ]] && exit 0

field() { printf '%s' "$input" | jq -r --arg k "$1" '.[$k] // empty' 2>/dev/null || true; }
cwd=$(field cwd)
[[ -n "$cwd" && -d "$cwd" ]] && cd "$cwd"
session=$(field session_id)
transcript=$(field transcript_path)
[[ -n "$session" ]] || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
cd "$(git rev-parse --show-toplevel)"

root="$(git rev-parse --git-common-dir)/cleanup-gate"
wt=$(pwd | cksum | cut -d' ' -f1)
state="$root/$session/$wt"
mkdir -p "$root"
find "$root" -mindepth 1 -maxdepth 1 -mtime +"$STATE_TTL_DAYS" -exec rm -rf {} + 2>/dev/null || true

# Dangling commit capturing tracked dirt (no ref, no stash entry); HEAD when clean.
snapshot() { git stash create 2>/dev/null | grep . || git rev-parse HEAD; }
transcript_lines() { if [[ -f "$transcript" ]]; then wc -l < "$transcript"; else echo 0; fi; }
baseline() {
  mkdir -p "$state"
  printf '%s\n' "$1" > "$state/base"
  git ls-files --others --exclude-standard > "$state/untracked"
  transcript_lines > "$state/offset"
}

if [[ "$(field hook_event_name)" == SessionStart ]]; then
  [[ -f "$state/base" ]] || baseline "$(snapshot)"
  exit 0
fi

if [[ ! -f "$state/base" ]]; then
  if [[ -d "$root/$session" ]]; then
    baseline "$(git rev-parse HEAD)"   # session entered or created this worktree: all its dirt is ours
    : > "$state/untracked"
  else
    baseline "$(snapshot)"; exit 0     # new session: pre-existing dirt is not ours
  fi
fi
base=$(cat "$state/base")
git cat-file -e "$base^{commit}" 2>/dev/null || { baseline "$(snapshot)"; exit 0; }

# Re-arm only on a host-written record of a /cleanup invocation after the last block.
# Claude Code logs the Skill tool call or the typed command; Codex logs the skill
# file being read (0.14x) or a skill input item (0.15x).
if [[ "$transcript" == *"/.codex/"* ]]; then
  pattern='skills/cleanup/SKILL\.md|"type": ?"skill"[^}]*cleanup'
else
  pattern='"skill": ?"cleanup"|<command-name>/cleanup</command-name>'
fi
offset=$(cat "$state/offset" 2>/dev/null || echo 0)
# Drain the tail so an early match cannot cause SIGPIPE under pipefail.
if [[ -f "$transcript" ]] && tail -n +"$((offset + 1))" "$transcript" | grep -E "$pattern" > /dev/null; then
  baseline "$(snapshot)"; exit 0
fi

tracked=$(git diff --numstat "$base" -- | awk '$1 != "-" {s+=$1} $2 != "-" {s+=$2} END {print s+0}')
new_files=$(git ls-files --others --exclude-standard | grep -vxFf "$state/untracked" || true)
untracked_lines=$(printf '%s\n' "$new_files" |
  while IFS= read -r f; do if [[ -f "$f" ]]; then wc -l < "$f"; fi; done | awk '{s+=$1} END {print s+0}')
delta=$((tracked + untracked_lines))
(( delta >= THRESHOLD_LINES )) || exit 0

now=$(date +%s)
last=$(cat "$state/last" 2>/dev/null || echo 0)
(( now - last >= INTERVAL_SECS )) || exit 0
printf '%s\n' "$now" > "$state/last"
transcript_lines > "$state/offset"

sha7=$(git rev-parse --short "$base")
printf '{"decision":"block","reason":"This session changed %s lines since %s without a cleanup pass. Run `/cleanup %s` now, then continue. The gate re-arms only after /cleanup runs."}\n' "$delta" "$sha7" "$sha7"
