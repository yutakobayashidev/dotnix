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
alias ct="continues"

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
alias ashiba="nfi github:yutakobayashidev/ashiba"
alias ndt="nfi github:the-nix-way/dev-templates"

# Security
scorecard() { GITHUB_AUTH_TOKEN="$(gh auth token)" command scorecard "$@"; }

alias p="pnpm"
alias ls="lsd -1A"
alias ll="lsd -l"
alias la="lsd -la"
alias lt="lsd --tree"
alias cat="bat"
alias gg="ghq get"
alias browse-pr="gh pr view --web"
alias isv='gh issue list | fzf-tmux --prompt "issue preview>" --preview "echo {} | awk '\''{print \$1}'\'' | xargs gh issue view -p" | xargs gh issue view'
alias prv='gh pr list | fzf-tmux --prompt "pr preview>" --preview "echo {} | awk '\''{print \$1}'\'' | xargs gh pr view -p" | xargs gh pr view'
alias browse="gh repo view --web"
alias brc='echo "$(gh repo view --json url --jq .url)/commit/$(git rev-parse HEAD)"'
alias gundo="git reset --soft HEAD~1"
alias grepush="git recommit && git push -f"
alias gsp="git stash && git pull && git stash pop"
alias gpgp="git pull && git push"
alias gpu="git pull"
alias rmswap="find . -type f -name \"*.swp\" -delete && find . -type f -name \".*.swp\" -delete"
