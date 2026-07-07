#!/usr/bin/env zsh
set -euo pipefail

case "$(uname)" in
Darwin)
  afplay /System/Library/Sounds/Pop.aiff &
  ;;
*)
  # Terminal bell — travels through SSH/tmux to the local terminal
  printf '\a' > /dev/tty
  ;;
esac
