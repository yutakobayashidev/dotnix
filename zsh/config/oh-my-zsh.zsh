#!/usr/bin/env zsh

# ========================================
# oh-my-zsh configuration
# ========================================

# oh-my-zshのパス（Home Managerで管理されている）
export ZSH="$HOME/.oh-my-zsh"

# テーマ
ZSH_THEME="agnoster"

# プラグイン
plugins=(
  git
  docker
  kubectl
  history
  sudo
  bgnotify
)

# oh-my-zshを読み込み
source $ZSH/oh-my-zsh.sh

# oh-my-zsh gitプラグインのエイリアスを解除
unalias g 2>/dev/null
unalias gb 2>/dev/null
unalias gwt 2>/dev/null
