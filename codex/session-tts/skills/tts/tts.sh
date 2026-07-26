#!/bin/bash
# session-tts skill entry point.
# Usage: tts.sh on|off|toggle|status

set -e

action="${1:-status}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=codex/session-tts/scripts/lib/runtime.sh
. "$script_dir/../../scripts/lib/runtime.sh"

session_id=$(session_tts_session_id)

if [ -z "$session_id" ]; then
  echo "session-tts: SESSION_TTS_SESSION_ID is not set" >&2
  exit 1
fi

data_dir=$(session_tts_data_dir)
silenced_dir="$data_dir/silenced"
pidfile_dir="$data_dir/playback"
silenced_file="$silenced_dir/$session_id"
pidfile="$pidfile_dir/$session_id"

kill_current_playback() {
  [ -f "$pidfile" ] || return 0
  local pgid
  pgid=$(cat "$pidfile" 2>/dev/null || echo "")
  if [ -n "$pgid" ]; then
    kill -TERM -- "-$pgid" 2>/dev/null || true
  fi
  rm -f "$pidfile"
}

silence_on() {
  mkdir -p "$silenced_dir"
  touch "$silenced_file"
  kill_current_playback
  echo "Session TTS (this session): OFF"
}

silence_off() {
  rm -f "$silenced_file"
  echo "Session TTS (this session): ON"
}

case "$action" in
on)
  silence_off
  ;;
off)
  silence_on
  ;;
toggle)
  if [ -e "$silenced_file" ]; then
    silence_off
  else
    silence_on
  fi
  ;;
status)
  if [ -e "$silenced_file" ]; then
    echo "Session TTS (this session): OFF"
  else
    echo "Session TTS (this session): ON"
  fi
  ;;
*)
  echo "usage: tts.sh on|off|toggle|status" >&2
  exit 1
  ;;
esac
