#!/usr/bin/env bash
# Stop hook: when the working tree has drifted far enough for long enough,
# block the turn once and instruct the agent to run /cleanup.
# Marker file caps nagging to once per interval regardless of outcome.
set -euo pipefail

THRESHOLD_LINES=${CLEANUP_GATE_LINES:-200}
INTERVAL_SECS=${CLEANUP_GATE_SECS:-1800}

input=$(cat)
# Never re-block while a previous block is being handled.
if [[ "$input" == *'"stop_hook_active":true'* ]]; then exit 0; fi

git rev-parse --git-dir >/dev/null 2>&1 || exit 0
mark="$(git rev-parse --git-dir)/claude-cleanup-mark"

now=$(date +%s)
last=$(cat "$mark" 2>/dev/null || echo 0)
(( now - last >= INTERVAL_SECS )) || exit 0

lines=$(git diff HEAD --shortstat 2>/dev/null |
  grep -oE '[0-9]+ (insertion|deletion)' | awk '{s+=$1} END {print s+0}')
(( lines >= THRESHOLD_LINES )) || exit 0

echo "$now" > "$mark"
cat <<EOF
{"decision": "block", "reason": "Cleanup checkpoint: the working tree has $lines changed lines vs HEAD and no cleanup ran in the last $((INTERVAL_SECS / 60)) minutes. Invoke the cleanup skill now on the current diff (clean agent gets the diff, the original request, the plan file, and explicit user constraints), then continue where you left off."}
EOF
