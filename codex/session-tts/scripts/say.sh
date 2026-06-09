#!/bin/bash
# Speaks a short Japanese phrase in the current session's voice.
#
# Usage: say.sh "<short Japanese text>"
#
# session_id is resolved from environment (PLUGIN_ROOT set by hooks,
# or from script location for Bash tool calls).

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_root="$(cd "$script_dir/.." && pwd)"

# shellcheck source=codex/session-tts/scripts/lib/voice-context.sh
. "$plugin_root/scripts/lib/voice-context.sh"

text="${1:-}"
session_id="${CODEX_THREAD_ID:-}"

[ -z "$text" ] && exit 0

speaker_id=$(resolve_speaker "$session_id") || exit 0

speak_text "$speaker_id" "$text" "$session_id"
