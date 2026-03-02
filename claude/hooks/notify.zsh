#!/usr/bin/env zsh
set -euo pipefail

case "$(uname)" in
Darwin)
  afplay /System/Library/Sounds/Pop.aiff &

  if [[ -n "${CMUX_TAB_ID:-}" ]] && command -v cmux &>/dev/null; then
    cmux select-workspace --workspace "$CMUX_TAB_ID"
  elif echo "$VSCODE_GIT_ASKPASS_MAIN" | grep -q Cursor 2>/dev/null; then
    osascript -e 'tell application "Cursor" to activate'
  elif [[ "${TERM_PROGRAM:-}" == "ghostty" ]]; then
    osascript -e 'tell application "Ghostty" to activate'
  fi
  ;;
*)
  # Terminal bell — travels through SSH/tmux to the local terminal
  printf '\a' > /dev/tty
  ;;
esac
