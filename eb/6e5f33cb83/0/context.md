# Session Context

## User Prompts

### Prompt 1

ct() {
  CLAUDE_CODE_TEAMMATE_COMMAND="claude -w $*" \
  claude --dangerously-skip-permissions --teammate-mode tmux "$@"
} こんな感じの生やしてほしい

### Prompt 2

コミットして

