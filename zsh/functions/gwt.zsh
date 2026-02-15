#!/usr/bin/env zsh

# gwt: git worktreeをfzf検索して移動
function gwt() {
  local worktree=$(git wt | fzf --header-lines=1 --prompt="git worktree > " | awk '{if ($1 == "*") print $2; else print $1}')
  if [[ -n "$worktree" ]]; then
    cd "$worktree"
  fi
}
