#!/usr/bin/env zsh

autoload -Uz add-zsh-hook chpwd_recent_dirs cdr
zstyle ':chpwd:*' recent-dirs-max 500
zstyle ':chpwd:*' recent-dirs-default true
add-zsh-hook chpwd chpwd_recent_dirs

cdf() {
  local dir

  dir=$(
    cdr -l 2>/dev/null \
      | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//' \
      | fzf --no-multi --exit-0 --query="$*" \
          --preview 'dir=$(printf "%s" {}); case "$dir" in "~/"*) dir="$HOME/${dir#\~/}" ;; "~") dir="$HOME" ;; esac; eza -F -alh --no-user --time-style=long-iso --icons --git --color=always "$dir" 2>/dev/null || ls -FA1 "$dir"'
  )

  [[ -n "$dir" ]] || return
  cd -- "${dir/#\~/$HOME}" || return
}
