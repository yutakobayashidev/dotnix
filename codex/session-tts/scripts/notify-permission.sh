#!/bin/bash
# PermissionRequest hook adapter.
#
# Composes a workspace-aware Japanese phrase and forwards it to the core.
# Codex PermissionRequest fires when Codex is about to ask for approval
# (shell escalation, managed-network approval, etc.).

set -e

# shellcheck source=lib/voice-context.sh
. "${PLUGIN_ROOT}/scripts/lib/voice-context.sh"

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

if [ -n "$cwd" ]; then
  workspace=$(basename "$cwd")
  text="${workspace}で承認待ちです。"
else
  text="承認待ちです。"
fi

speaker_id=$(resolve_speaker "$session_id") || exit 0
speak_text "$speaker_id" "$text" "$session_id"
