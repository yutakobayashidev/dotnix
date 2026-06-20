#!/usr/bin/env zsh

# ghauth: ghtkn のデバイス認証コードをクリップボードへコピー
function ghauth() {
  ghtkn auth "$@" 2>&1 |
    tee >(grep -oE "[A-Z0-9]{4}-[A-Z0-9]{4}" --line-buffered | head -n1 | tr -d "\n" | pbcopy)
}
