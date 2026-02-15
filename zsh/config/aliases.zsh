#!/usr/bin/env zsh

# ========================================
# Aliases
# ========================================

alias rebuild="nh os switch && source ~/.zshrc"
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
alias cpd="pwd | wl-copy"
alias rmswap="find . -type f -name \"*.swp\" -delete && find . -type f -name \".*.swp\" -delete"
