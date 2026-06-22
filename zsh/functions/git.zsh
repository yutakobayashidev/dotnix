#!/usr/bin/env zsh

# g: 引数なし→ghq+fzfでcd、引数あり→gitに転送
function __ghq_pick() {
  local selected_dir
  selected_dir="$(
    ghq list --full-path \
      | roots \
      | fzf --height 40% --reverse \
          --preview 'eza --tree --level=2 --git-ignore --color=always --icons {} 2>/dev/null || ls {}'
  )"

  [[ -n "$selected_dir" ]] && printf '%s\n' "$selected_dir"
}

function g() {
  if [[ $# -eq 0 ]]; then
    local selected_dir
    selected_dir="$(__ghq_pick)" || return
    [[ -n "$selected_dir" ]] && cd -- "$selected_dir"
  else
    git "$@"
  fi
}

# worktree: git worktreeをfzf検索して移動
function worktree() {
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

branch() {
  # https://github.com/junegunn/fzf/issues/1693#issuecomment-699642792
  git branch --sort=-authordate "$@" \
    | grep --invert-match HEAD \
    | fzf --print-query --cycle --exit-0 --no-multi \
        --header-first --header='Create new branch when query is not matched' \
        --preview="sed -E 's/. ([^ ]+).*/\1/' <<< {} | xargs git log -30 --pretty=format:'[%ad] %s <%an>' --date=format:'%F'" \
    | tail -1 \
    | sed -E 's#. (.*origin/)?([^ ]+).*#\2#' \
    | xargs -I_ git twig _
}

cdg() {
  cd "$(git rev-parse --show-toplevel)" || return
}

stash() {
  git stash save "${1:-$(date +%Y%m%d%H%M%S)}"
}

fpull() {
  git fetch

  if git diff --quiet HEAD..origin; then
    echo 'Working tree is up-to-date.'
    return 0
  fi

  if git status --short --null --untracked-files=no | grep --quiet .; then
    git stash
    git pull
    git stash pop
  else
    git pull
  fi
}

function __ghq_pick_widget() {
  local selected_dir
  selected_dir="$(__ghq_pick)" || return

  if [[ -n "$selected_dir" ]]; then
    cd -- "$selected_dir" || return
    zle reset-prompt
  fi
}
zle -N __ghq_pick_widget
bindkey '^G' __ghq_pick_widget
