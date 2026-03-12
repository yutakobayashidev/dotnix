#!/usr/bin/env zsh

# gh-auth-switch: ghqディレクトリに入ったらgh authを自動切り替え
# マッピングに該当しないownerはデフォルトアカウントを使用

GH_AUTH_DEFAULT_USER="yutakobayashidev"

# owner → アカウントのマッピング（アカウント追加時にここを編集）
typeset -gA GH_AUTH_ACCOUNT_MAP=(
  # "some-org" "work-account"
)

function _gh_auto_switch() {
  local ghq_root="${GHQ_ROOT:-$(ghq root 2>/dev/null)}"
  [[ -z "$ghq_root" || "$PWD" != "$ghq_root"/* ]] && return

  # パスからowner抽出: ghq_root/github.com/<owner>/...
  local rel="${PWD#$ghq_root/}"
  local host="${rel%%/*}"
  [[ "$host" != "github.com" ]] && return

  local owner=$(echo "$rel" | cut -d'/' -f2)
  [[ -z "$owner" ]] && return

  local target="${GH_AUTH_ACCOUNT_MAP[$owner]:-$GH_AUTH_DEFAULT_USER}"

  # 現在のアカウントをキャッシュと比較（gh auth statusは遅いので避ける）
  if [[ "$_GH_CURRENT_USER" != "$target" ]]; then
    gh auth switch --user "$target" 2>/dev/null && _GH_CURRENT_USER="$target"
  fi
}

# 初期値をセット
_GH_CURRENT_USER="$GH_AUTH_DEFAULT_USER"

autoload -U add-zsh-hook
add-zsh-hook chpwd _gh_auto_switch
