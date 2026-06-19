#!/usr/bin/env zsh

# W: git worktreeをfzf検索して移動
function W() {
  local selected

  selected=$(
    git wt --json \
      | jq -r '.[] | [
          (if .current then "*" else " " end),
          .branch,
          .path,
          .head
        ] | @tsv' \
      | fzf --tmux --reverse \
          --with-nth=1,2 \
          --delimiter=$'\t' \
          --preview 'git -C {3} log --oneline --graph -20' \
      | cut -f3
  )

  if [[ -n "$selected" ]]; then
    cd "$selected"
  fi
}
