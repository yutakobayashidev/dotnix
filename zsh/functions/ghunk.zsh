#!/usr/bin/env zsh

# ghunk: fzf で開始・終了コミットを選び、その両端を含む差分を Hunk で開く。
function ghunk() {
  local from_commit to_commit from_hash to_hash base
  local -a end_range

  git rev-parse --verify HEAD >/dev/null 2>&1 || return 1
  from_commit=$(
    git log --oneline --decorate -100 --color=never |
      fzf --header 'Hunk: 開始コミットを含めて比較' \
        --prompt 'From> ' \
        --preview 'git show --stat --color=always {1}'
  ) || return
  [[ -n "$from_commit" ]] || return
  from_hash="${from_commit%% *}"

  if base=$(git rev-parse --verify "$from_hash^" 2>/dev/null); then
    end_range=("$base..HEAD")
  else
    # 最初のコミットには親がないため、空のツリーから比較する。
    base=$(git hash-object -t tree --stdin </dev/null) || return
    end_range=(HEAD)
  fi

  to_commit=$(
    git log --oneline --decorate --color=never "${end_range[@]}" |
      fzf --header "Hunk: $from_hash から終了コミットまで" \
        --prompt 'To> ' \
        --preview 'git show --stat --color=always {1}'
  ) || return
  [[ -n "$to_commit" ]] || return
  to_hash="${to_commit%% *}"

  hunk diff "$base" "$to_hash"
}
