#!/bin/bash
# session-tts-volume skill entry point.
# Usage: volume.sh <0.0-1.0> | status | reset

set -e

action="${1:-status}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=codex/session-tts/scripts/lib/runtime.sh
. "$script_dir/../../scripts/lib/runtime.sh"

data_dir=$(session_tts_data_dir)
volume_file="$data_dir/volume"
default_volume="0.8"

show_status() {
  if [ -f "$volume_file" ]; then
    local current
    current=$(cat "$volume_file" 2>/dev/null || echo "")
    if [ -n "$current" ]; then
      echo "Session TTS volume: $current (default: $default_volume)"
      return
    fi
  fi
  echo "Session TTS volume: $default_volume (default)"
}

set_volume() {
  local value="$1"
  if ! [[ $value =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "session-tts-volume: value must be a decimal in [0.0, 1.0]" >&2
    exit 1
  fi
  if ! awk -v v="$value" 'BEGIN { exit (v >= 0.0 && v <= 1.0) ? 0 : 1 }' </dev/null; then
    echo "session-tts-volume: value must be a decimal in [0.0, 1.0]" >&2
    exit 1
  fi
  mkdir -p "$data_dir"
  printf '%s\n' "$value" >"$volume_file"
  echo "Session TTS volume: $value"
}

reset_volume() {
  rm -f "$volume_file"
  echo "Session TTS volume: $default_volume (default)"
}

case "$action" in
status)
  show_status
  ;;
reset)
  reset_volume
  ;;
*)
  set_volume "$action"
  ;;
esac
