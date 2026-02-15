#!/usr/bin/env zsh

# Alt+Up で親ディレクトリに移動
function cd-up() {
  cd ..
  zle reset-prompt
}
zle -N cd-up
bindkey '^[[1;3A' cd-up
