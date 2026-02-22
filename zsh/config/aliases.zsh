#!/usr/bin/env zsh

# ========================================
# Aliases
# ========================================

# Platform-specific aliases
if [[ "$(uname)" == "Darwin" ]]; then
  alias rebuild="darwin-rebuild switch --flake ~/ghq/github.com/yutakobayashidev/dotnix && source ~/.zshrc"
  alias cpd="pwd | pbcopy"
else
  alias rebuild="nh os switch && source ~/.zshrc"
  alias cpd="pwd | wl-copy"
fi

alias cc="claude"
alias yolo="claude --dangerously-skip-permissions"
alias p="pnpm"
alias ls="lsd -1A"
alias ll="lsd -l"
alias la="lsd -la"
alias lt="lsd --tree"
alias cat="bat"
alias prw="gh pr view --web"
alias gundo="git reset --soft HEAD~1"
alias rmswap="find . -type f -name \"*.swp\" -delete && find . -type f -name \".*.swp\" -delete"
