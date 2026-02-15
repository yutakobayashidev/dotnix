#!/usr/bin/env zsh

# gh-q: ghq + fzf でリポジトリ選択・clone
# https://github.com/ryoppippi/dotfiles/blob/5a0a1f1d68b66a89c2c916c9e97c0129251ca467/fish/functions/gh-q.fish
# 使い方: gh-q [-o] [owner]  (ownerを省略すると自分のrepo、-oでGitHubを開く)
function gh-q() {
  local open_github=false
  if [[ "$1" == "-o" ]]; then
    open_github=true
    shift
  fi

  local owner="$1"
  if [[ -z "$owner" ]]; then
    owner=$(gh api user -q .login)
  fi

  local query='
query ($owner: String!, $endCursor: String) {
  repositoryOwner(login: $owner) {
    repositories(first: 30, after: $endCursor) {
      pageInfo { hasNextPage endCursor }
      nodes { nameWithOwner }
    }
  }
}'

  local REPO=$(gh api graphql \
    --paginate \
    --field owner="$owner" \
    -f query="$query" \
    --jq '.data.repositoryOwner.repositories.nodes[].nameWithOwner' \
  | fzf)

  if [[ -z "$REPO" ]]; then
    return
  fi

  if $open_github; then
    xdg-open "https://github.com/$REPO"
  else
    ghq get "$REPO"
    cd "$(ghq root)/github.com/$REPO"
  fi
}
