# Session Context

## User Prompts

### Prompt 1

#!/bin/bash
set -euo pipefail

# git-wt-clean: リモートでマージ済み(gone)のworktreeとブランチを一括削除

git fetch --prune

branches=$(git branch -vv | grep ': gone]' | sed 's/^[* +]*//' | awk '{print $1}')

if [ -z "$branches" ]; then
  echo "削除対象のブランチはありません"
  exit 0
fi

echo "削除対象:"
echo "$branches" | while read branch; do
  echo "  - $branch"
done
echo ""

read -p "削除しますか？ [y/N] " answer
if [[ "$answer" != [yY] ]]; then...

### Prompt 2

コミットしといて

