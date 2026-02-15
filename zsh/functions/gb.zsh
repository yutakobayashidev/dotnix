#!/usr/bin/env zsh

# gb: git branchをfuzzy検索して移動
function gb() {
  local branch=$(git branch --all | grep -v HEAD | sed 's/^[* ]*//' | sed 's#remotes/origin/##' | sort -u | fzf --prompt="git branch > ")
  if [[ -n "$branch" ]]; then
    git checkout "$branch"
  fi
}
