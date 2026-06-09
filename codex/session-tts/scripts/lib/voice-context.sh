# shellcheck shell=bash
# Shared helpers for session-tts adapters. Source this file from any adapter
# script that needs to resolve the per-session voice and forward text to the
# core (say-response.py).
#
# resolve_speaker <session_id>
#   Prints the assigned speaker id on stdout. Returns 1 if the session has
#   no voice assigned or has been silenced via /session-tts:tts off.
#
# speak_text <speaker_id> <text> <session_id>
#   Forwards the given text to session-tts-say-response (a Nix-wrapped
#   Python binary) with the speaker and session id injected via env.
#
# Plugin root resolution:
#   Codex sets PLUGIN_ROOT for hook invocations and also sets CLAUDE_PLUGIN_ROOT
#   for backward compatibility. For Bash tool calls (skill adapters), PLUGIN_ROOT
#   may not be set, so we fall back to resolving from this file's own location.

resolve_speaker() {
  local session_id="$1"
  local data_dir="${CODEX_HOME:?}/session-tts"
  local session_file="$data_dir/sessions/$session_id"
  local silenced_file="$data_dir/silenced/$session_id"

  [ -z "$session_id" ] && return 1
  [ ! -e "$session_file" ] && return 1
  [ -e "$silenced_file" ] && return 1

  local speaker_id
  speaker_id=$(cat "$session_file" 2>/dev/null || echo "")
  [ -z "$speaker_id" ] && return 1

  printf '%s' "$speaker_id"
}

speak_text() {
  local speaker_id="$1"
  local text="$2"
  local session_id="$3"
  printf '%s' "$text" |
    SESSION_TTS_SPEAKER_ID="$speaker_id" \
      SESSION_TTS_SESSION_ID="$session_id" \
      SESSION_TTS_ENGINE_URL="https://aivisspeech.home.yutakobayashi.com" \
      session-tts-say-response
}
