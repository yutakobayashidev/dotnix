#!/usr/bin/env zsh

# git-wt-clean: リモートでマージ済み(gone)のworktreeとブランチを一括削除
function git-wt-clean() {
  git fetch --prune

  local branches=$(git branch -vv | grep ': gone]' | sed 's/^[* +]*//' | awk '{print $1}')

  if [ -z "$branches" ]; then
    echo "削除対象のブランチはありません"
    return 0
  fi

  echo "削除対象:"
  echo "$branches" | while read -r branch; do
    echo "  - $branch"
  done
  echo ""

  read -r "answer?削除しますか？ [y/N] "
  if [[ "$answer" != [yY] ]]; then
    echo "キャンセルしました"
    return 0
  fi

  echo "$branches" | while read -r branch; do
    echo "削除中: $branch"
    git wt -d "$branch" 2>/dev/null || { echo "  worktreeなし、ブランチのみ削除します"; git branch -d "$branch" 2>/dev/null || true; }
  done

  echo "完了"
}
