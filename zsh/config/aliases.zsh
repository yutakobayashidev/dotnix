#!/usr/bin/env zsh

# ========================================
# Aliases
# ========================================

# rebuild - unified via flake apps
alias rebuild="nix run ~/ghq/github.com/yutakobayashidev/dotnix#switch && source ~/.zshrc"

# Platform-specific aliases
if [[ "$(uname)" == "Darwin" ]]; then
  alias cpd="pwd | pbcopy"
else
  alias cpd="pwd | wl-copy"
fi

# AI tools
alias cl="claude"
alias cld="claude --dangerously-skip-permissions"
alias cldc="claude --dangerously-skip-permissions --continue"
alias clh="claude --dangerously-skip-permissions --model haiku"
alias clo="claude --dangerously-skip-permissions --model opus"
alias cls="claude --dangerously-skip-permissions --model sonnet"
alias oc="opencode"
alias cx="codex"
alias ca="cursor-agent"

# Docker
alias do="docker container"
alias dop="docker container ps"
alias dob="docker container build"
alias dor="docker container run --rm"
alias dox="docker container exec -it"

# Docker Compose
alias dc="docker compose"
alias dcu="docker compose up"
alias dcub="docker compose up --build"
alias dcd="docker compose down"
alias dcr="docker compose restart"

# Nix
alias ns="nix-shell"
alias ngc="nix-collect-garbage"
nrn() { nix run "nixpkgs#$1" "${@:2}"; }
ashiba() { nix flake init -t "github:yutakobayashidev/ashiba#$1"; }

alias p="pnpm"
alias ls="lsd -1A"
alias ll="lsd -l"
alias la="lsd -la"
alias lt="lsd --tree"
alias cat="bat"
alias gg="ghq get"
alias prw="gh pr view --web"
alias gundo="git reset --soft HEAD~1"
alias rmswap="find . -type f -name \"*.swp\" -delete && find . -type f -name \".*.swp\" -delete"
