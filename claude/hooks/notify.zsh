#!/usr/bin/env zsh
set -euo pipefail

case "$(uname)" in
Darwin)
  afplay /System/Library/Sounds/Pop.aiff &

  local cmux_bin=""
  if (( $+commands[cmux] )); then
    cmux_bin="$(command -v cmux)"
  elif [[ -x "/Applications/cmux.app/Contents/Resources/bin/cmux" ]]; then
    cmux_bin="/Applications/cmux.app/Contents/Resources/bin/cmux"
  fi

  if [[ -n "${CMUX_TAB_ID:-}" && -n "$cmux_bin" ]]; then
    "$cmux_bin" set-app-focus active
    "$cmux_bin" select-workspace --workspace "$CMUX_TAB_ID"
  fi
  ;;
*)
  # Terminal bell — travels through SSH/tmux to the local terminal
  printf '\a' > /dev/tty
  ;;
esac
