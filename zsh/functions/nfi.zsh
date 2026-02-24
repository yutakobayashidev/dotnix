#!/usr/bin/env zsh

# nfi: nix flake init with fuzzy template selection
# 使い方: nfi <flake_ref> [template_name]
#   例: nfi github:yutakobayashidev/ashiba        # fzf でテンプレート選択
#       nfi github:someone/templates next          # 直接指定
function nfi() {
  local flake_ref="$1"
  local template="$2"

  [[ -z "$flake_ref" ]] && { echo "Usage: nfi <flake_ref> [template]" >&2; return 1 }

  if [[ -z "$template" ]]; then
    local items
    items=$(nix flake show "$flake_ref" --json --refresh 2>/dev/null \
      | jq -r '.templates | to_entries[] | "\(.key)\t\(.value.description)"')
    if [[ -z "$items" ]]; then
      echo "Failed to fetch templates from $flake_ref" >&2
      return 1
    fi
    template=$(echo "$items" | fzf --header "Template" --delimiter='\t' --with-nth=1.. | cut -f1)
    [[ -z "$template" ]] && return 1
  fi

  nix flake init -t "$flake_ref#$template"
}
