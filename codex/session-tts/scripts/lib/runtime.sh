# shellcheck shell=bash

session_tts_data_dir() {
  if [ -n "${SESSION_TTS_HOME:-}" ]; then
    printf '%s' "$SESSION_TTS_HOME"
    return
  fi

  printf '%s/session-tts' "${XDG_STATE_HOME:-${HOME:?}/.local/state}"
}

session_tts_session_id() {
  printf '%s' "${SESSION_TTS_SESSION_ID:-${CODEX_THREAD_ID:-}}"
}
