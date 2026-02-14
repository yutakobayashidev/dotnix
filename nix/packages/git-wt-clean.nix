{ lib, writeShellApplication, git }:

writeShellApplication {
  name = "git-wt-clean";

  runtimeInputs = [ git ];

  text = ''
    # git-wt-clean: リモートでマージ済み(gone)のworktreeとブランチを一括削除

    git fetch --prune

    branches=$(git branch -vv | grep ': gone]' | sed 's/^[* +]*//' | awk '{print $1}')

    if [ -z "$branches" ]; then
      echo "削除対象のブランチはありません"
      exit 0
    fi

    echo "削除対象:"
    echo "$branches" | while read -r branch; do
      echo "  - $branch"
    done
    echo ""

    read -rp "削除しますか？ [y/N] " answer
    if [[ "$answer" != [yY] ]]; then
      echo "キャンセルしました"
      exit 0
    fi

    echo "$branches" | while read -r branch; do
      echo "削除中: $branch"
      git wt -d "$branch" 2>/dev/null || { echo "  worktreeなし、ブランチのみ削除します"; git branch -d "$branch" 2>/dev/null || true; }
    done

    echo "完了"
  '';

  meta = with lib; {
    description = "リモートでマージ済み(gone)のworktreeとブランチを一括削除";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "git-wt-clean";
  };
}
