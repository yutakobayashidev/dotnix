#!/bin/bash
# Shared reminder hook adapter for session-tts.
#
# Usage: remind-say.sh <trigger>
#   <trigger> ∈ { prompt | subagent }
#
# Reads the hook payload from stdin (for the session_id) and, when the
# session has a voice and is not silenced, outputs a trigger-specific
# reminder so Codex is nudged to narrate progress via the Bash tool +
# `${PLUGIN_ROOT}/scripts/say.sh`.

set -e

trigger="${1:-}"
[ -z "$trigger" ] && exit 0

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')

data_dir="$HOME/.codex/session-tts"
[ -z "$session_id" ] && exit 0
[ ! -e "$data_dir/sessions/$session_id" ] && exit 0
[ -e "$data_dir/silenced/$session_id" ] && exit 0

plugin_root="${PLUGIN_ROOT}"
cmd="bash \"$plugin_root/scripts/say.sh\" \"<phrase>\""

# Tail of every reminder — kept short and identical so the model
# pattern-matches it as boilerplate it can compress.
tail_common="Call Bash (synchronous; do NOT pass run_in_background) with command: \`$cmd\`. Open with a brief lead-in (報告です / 着手します / 完了です / 発見です / 方針転換です など), keep it under ~100 Japanese characters. The call blocks until playback finishes, so report only at real milestones. Skip if you just narrated in the immediately preceding step."

case "$trigger" in
subagent)
  event="SubagentStart"
  head="You are delegating to a subagent. Narrate WHAT you are delegating and WHY before starting it."
  ;;
prompt)
  # UserPromptSubmit: stdout is auto-injected as context. No JSON.
  cat <<EOF
[session-tts] User prompt received. If this turn becomes multi-step,
narrate at milestones (transition / problem / finding / pivot).
$tail_common
EOF
  exit 0
  ;;
*)
  exit 0
  ;;
esac

jq -n --arg event "$event" --arg msg "[session-tts] $head $tail_common" \
  '{ hookSpecificOutput: { hookEventName: $event, additionalContext: $msg } }'
