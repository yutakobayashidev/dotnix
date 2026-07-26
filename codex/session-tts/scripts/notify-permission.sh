#!/bin/bash
# PermissionRequest hook adapter.
#
# Composes a workspace-aware Japanese phrase and forwards it to the core.
# Codex PermissionRequest fires when Codex is about to ask for approval
# (shell escalation, managed-network approval, etc.).

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=codex/session-tts/scripts/lib/voice-context.sh
. "$script_dir/lib/voice-context.sh"

input=$(cat)
session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

if [ -n "$cwd" ]; then
  workspace=$(basename "$cwd")
  text="${workspace}で承認待ちです。"
else
  text="承認待ちです。"
fi

speaker_id=$(resolve_speaker "$session_id") || exit 0
speak_text "$speaker_id" "$text" "$session_id"
