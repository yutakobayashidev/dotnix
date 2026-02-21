#!/usr/bin/env zsh

# ct: Claude Code teammate mode (tmux)
function ct() {
  CLAUDE_CODE_TEAMMATE_COMMAND="claude -w $*" \
  claude --dangerously-skip-permissions --teammate-mode tmux "$@"
}
