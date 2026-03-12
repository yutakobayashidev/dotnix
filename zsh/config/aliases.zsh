#!/usr/bin/env zsh

# ========================================
# Abbreviations (zsh-abbr) & Aliases
# ========================================

# rebuild - unified via flake apps
abbr -f -qq rebuild="nix run ~/ghq/github.com/yutakobayashidev/dotnix#switch && source ~/.zshrc"

# Platform-specific abbreviations
if [[ "$(uname)" == "Darwin" ]]; then
  abbr -f -qq cpd="pwd | pbcopy"
else
  abbr -f -qq cpd="pwd | wl-copy"
fi

# AI tools
abbr -f -qq cl="claude"
abbr -f -qq cld="claude --dangerously-skip-permissions"
abbr -f -qq cldc="claude --dangerously-skip-permissions --continue"
abbr -f -qq clh="claude --dangerously-skip-permissions --model haiku"
abbr -f -qq clo="claude --dangerously-skip-permissions --model opus"
abbr -f -qq cls="claude --dangerously-skip-permissions --model sonnet"
abbr -f -qq oc="opencode"
abbr -f -qq cx="codex"
abbr -f -qq ca="cursor-agent"
abbr -f -qq ct="continues"

# Docker
abbr -f -qq do="docker container"
abbr -f -qq dop="docker container ps"
abbr -f -qq dob="docker container build"
abbr -f -qq dor="docker container run --rm"
abbr -f -qq dox="docker container exec -it"

# Docker Compose
abbr -f -qq dc="docker compose"
abbr -f -qq dcu="docker compose up"
abbr -f -qq dcub="docker compose up --build"
abbr -f -qq dcd="docker compose down"
abbr -f -qq dcr="docker compose restart"

# Nix
abbr -f -qq ns="nix-shell"
abbr -f -qq ngc="nix-collect-garbage"
nrn() { nix run "nixpkgs#$1" "${@:2}"; }
abbr -f -qq ashiba="nfi github:yutakobayashidev/ashiba"
abbr -f -qq ndt="nfi github:the-nix-way/dev-templates"

# Security
scorecard() { GITHUB_AUTH_TOKEN="$(gh auth token)" command scorecard "$@"; }

abbr -f -qq p="pnpm"
abbr -f -qq gg="ghq get"

# Command replacements (keep as aliases — no visual expansion needed)
alias ls="lsd -1A"
alias ll="lsd -l"
alias la="lsd -la"
alias lt="lsd --tree"
alias cat="bat"

# Git
abbr -f -qq browse-pr="gh pr view --web"
alias isv='gh issue list | fzf-tmux --prompt "issue preview>" --preview "echo {} | awk '\''{print \$1}'\'' | xargs gh issue view -p" | xargs gh issue view'
alias prv='gh pr list | fzf-tmux --prompt "pr preview>" --preview "echo {} | awk '\''{print \$1}'\'' | xargs gh pr view -p" | xargs gh pr view'
abbr -f -qq browse="gh repo view --web"
alias brc='echo "$(gh repo view --json url --jq .url)/commit/$(git rev-parse HEAD)"'
abbr -f -qq gundo="git reset --soft HEAD~1"
abbr -f -qq grepush="git recommit && git push -f"
abbr -f -qq gsp="git stash && git pull && git stash pop"
abbr -f -qq gpgp="git pull && git push"
abbr -f -qq gpu="git pull"
abbr -f -qq rmswap='find . -type f -name "*.swp" -delete && find . -type f -name ".*.swp" -delete'
