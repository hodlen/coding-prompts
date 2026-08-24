#!/usr/bin/env bash
# Periodically ask the agent to consider cleanup for a large branch diff.
set -euo pipefail

THRESHOLD_LINES=${CLEANUP_GATE_LINES:-200}
INTERVAL_SECS=${CLEANUP_GATE_SECS:-1800}

input=$(cat)
if [[ "$input" == *'"stop_hook_active":true'* ]]; then exit 0; fi

git rev-parse --git-dir >/dev/null 2>&1 || exit 0
mark="$(git rev-parse --git-dir)/claude-cleanup-mark"

now=$(date +%s)
last=$(cat "$mark" 2>/dev/null || echo 0)
(( now - last >= INTERVAL_SECS )) || exit 0

base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo main)
fork=$(git merge-base --fork-point "$base" HEAD 2>/dev/null ||
  git merge-base "$base" HEAD 2>/dev/null) || exit 0
head=$(git rev-parse HEAD)
fork_label=$(git rev-parse --short "$fork")
head_label=$(git rev-parse --short "$head")
lines=$(git diff --numstat "$fork" -- 2>/dev/null |
  awk '$1 != "-" {s+=$1} $2 != "-" {s+=$2} END {print s+0}')
(( lines >= THRESHOLD_LINES )) || exit 0
commits=$(git rev-list --count "$fork..$head")
staged=$(git diff --cached --name-only -- | awk 'END {print NR+0}')
unstaged=$(git diff --name-only -- | awk 'END {print NR+0}')
untracked=$(git ls-files --others --exclude-standard | awk 'END {print NR+0}')

echo "$now" > "$mark"
cat <<EOF
{"decision": "block", "reason": "Cleanup candidate: $fork_label..$head_label has $commits commits/$lines lines; dirty files $staged staged/$unstaged unstaged/$untracked untracked. Use this task's latest cleanup result, promote commits containing only its accepted dirty work, else start at $fork_label. Review what remains or skip when covered."}
EOF
