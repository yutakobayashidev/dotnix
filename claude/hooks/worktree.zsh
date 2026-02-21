#!/usr/bin/env zsh
set -euo pipefail

input=$(cat)
hook_event=$(printf '%s' "$input" | jq -r '.hook_event_name')

case "$hook_event" in
WorktreeCreate)
  wt_name=$(printf '%s' "$input" | jq -r '.name')
  wt_abs_path=$(git wt "$wt_name" --nocd 2>/dev/null | tail -n 1 | xargs)
  echo "$wt_abs_path"
  ;;
WorktreeRemove)
  wt_path=$(printf '%s' "$input" | jq -r '.worktree_path')
  git wt -d "$wt_path" 2>/dev/null || true
  ;;
esac
