#!/usr/bin/env zsh

# g: 引数なし→ghq+pecoでcd、引数あり→gitに転送
function g() {
  if [[ $# -eq 0 ]]; then
    local selected_dir=$(ghq list -p | peco --prompt="repositories >")
    if [ -n "$selected_dir" ]; then
      cd "$selected_dir"
    fi
  else
    git "$@"
  fi
}
