#!/bin/bash
# Speaks a short Japanese phrase in the current session's voice.
#
# Usage: say.sh "<short Japanese text>"
#
# session_id is resolved from the Codex environment.

set -e

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
session_tts_root="$(cd "$script_dir/.." && pwd)"

# shellcheck source=codex/session-tts/scripts/lib/voice-context.sh
. "$session_tts_root/scripts/lib/voice-context.sh"

text="${1:-}"
session_id=$(session_tts_session_id)

[ -z "$text" ] && exit 0

speaker_id=$(resolve_speaker "$session_id") || exit 0

speak_text "$speaker_id" "$text" "$session_id"
