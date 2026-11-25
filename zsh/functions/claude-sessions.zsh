# Claude Code Session History Display
# Shows recent session IDs when entering a directory with Claude Code history
# Triggered via zsh chpwd hook
# ref: https://github.com/ushironoko/dotfiles/blob/main/shell/functions/claude-sessions.sh

_claude_sessions_chpwd() {
  # Only in interactive terminals
  [[ ! -t 2 ]] && return

  # Require jq
  command -v jq &>/dev/null || return

  # Encode current directory path to Claude project dir format (/ and . → -)
  local project_dir="${PWD//\//-}"
  project_dir="${project_dir//./-}"
  local claude_path="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/$project_dir"

  # Get 3 most recent session files
  local -a files
  files=("$claude_path"/*.jsonl(N.om[1,3]))
  [[ ${#files[@]} -eq 0 ]] && return

  local -a sids
  local f sid s
  for f in "${files[@]}"; do
    sid=$(head -1 "$f" | command jq -r '.sessionId // empty' 2>/dev/null)
    [[ -n "$sid" ]] && sids+=("$sid")
  done

  [[ ${#sids[@]} -eq 0 ]] && return

  # Copy most recent session resume command to clipboard
  if command -v pbcopy &>/dev/null; then
    printf '%s' "claude --resume ${sids[1]}" | pbcopy
  elif command -v xclip &>/dev/null; then
    printf '%s' "claude --resume ${sids[1]}" | xclip -selection clipboard
  elif command -v wl-copy &>/dev/null; then
    printf '%s' "claude --resume ${sids[1]}" | wl-copy
  fi

  local idx=1
  for s in "${sids[@]}"; do
    printf '\e[2m%d. %s\e[0m\n' "$idx" "$s" >&2
    ((idx++))
  done
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _claude_sessions_chpwd
_claude_sessions_chpwd
