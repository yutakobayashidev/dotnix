#!/usr/bin/env zsh

# jb: jj bookmarkをfuzzy検索して移動
function jb() {
  local bookmark=$(jj bookmark list | fzf --prompt="jj bookmark > " | awk '{print $1}')
  if [[ -n "$bookmark" ]]; then
    jj new "$bookmark"
  fi
}
