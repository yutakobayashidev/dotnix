#!/usr/bin/env zsh

# ashiba: プロジェクトテンプレート初期化 (ghq create + nix flake init)
# 使い方: ashiba [--local] <name> [template_name]
function ashiba() {
  local flake_ref="github:yutakobayashidev/ashiba"
  local local_only=false
  local name=""
  local template=""

  # 引数パース
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --local) local_only=true; shift ;;
      *)
        if [[ -z "$name" ]]; then
          name="$1"
        else
          template="$1"
        fi
        shift ;;
    esac
  done

  # プロジェクト名
  if [[ -z "$name" ]]; then
    echo "Usage: ashiba [--local] <name> [template_name]" >&2
    return 1
  fi

  # テンプレート選択
  if [[ -z "$template" ]]; then
    local items
    items=$(nix flake show "$flake_ref" --json --refresh 2>/dev/null \
      | jq -r '.templates | to_entries[] | "\(.key)\t\(.value.description)"')
    if [[ -z "$items" ]]; then
      echo "Failed to fetch templates" >&2
      return 1
    fi
    template=$(echo "$items" | fzf --header "Template" --delimiter='\t' --with-nth=1.. | cut -f1)
    [[ -z "$template" ]] && return 1
  fi

  # ディレクトリ作成
  if [[ "$local_only" == true ]]; then
    mkdir -p "$name" && cd "$name"
  else
    ghq create "$name" || return 1
    cd "$(ghq root)/github.com/$(gh api user -q .login)/$name"
  fi

  nix flake init -t "$flake_ref#$template"
}
