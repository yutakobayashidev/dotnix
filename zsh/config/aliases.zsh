#!/usr/bin/env zsh

# ========================================
# Abbreviations (zsh-abbr) & Aliases
# ========================================

# rebuild - unified via flake apps
abbr -S -qq rebuild="nix run ~/ghq/github.com/yutakobayashidev/dotnix#switch && source ~/.zshrc"

# Platform-specific abbreviations
if [[ "$(uname)" == "Darwin" ]]; then
  abbr -S -qq cpd="pwd | pbcopy"
else
  abbr -S -qq cpd="pwd | wl-copy"
fi

# AI tools
abbr -S -qq cl="claude"
abbr -S -qq cld="claude --dangerously-skip-permissions"
abbr -S -qq cldc="claude --dangerously-skip-permissions --continue"
abbr -S -qq clh="claude --dangerously-skip-permissions --model haiku"
abbr -S -qq clo="claude --dangerously-skip-permissions --model opus"
abbr -S -qq cls="claude --dangerously-skip-permissions --model sonnet"
abbr -S -qq cg="cage"
abbr -S -qq cgcl="cage claude"
abbr -S -qq cgcx="cage codex"
abbr -S -qq oc="opencode"
abbr -S -qq cx="codex"
abbr -S -qq ca="cursor-agent"
abbr -S -qq ct="continues"

# Docker
abbr -S -qq do="docker container"
abbr -S -qq dop="docker container ps"
abbr -S -qq dob="docker container build"
abbr -S -qq dor="docker container run --rm"
abbr -S -qq dox="docker container exec -it"

# Docker Compose
abbr -S -qq dc="docker compose"
abbr -S -qq dcu="docker compose up"
abbr -S -qq dcub="docker compose up --build"
abbr -S -qq dcd="docker compose down"
abbr -S -qq dcr="docker compose restart"

# Nix
abbr -S -qq ns="nix-shell"
abbr -S -qq ngc="nix-collect-garbage"
nrn() { nix run "nixpkgs#$1" "${@:2}"; }
abbr -S -qq ashiba="nfi github:yutakobayashidev/ashiba"
abbr -S -qq ndt="nfi github:the-nix-way/dev-templates"

# Security
scorecard() { GITHUB_AUTH_TOKEN="$(gh auth token)" command scorecard "$@"; }

abbr -S -qq p="pnpm"
abbr -S -qq gg="ghq get"

# Command replacements (keep as aliases — no visual expansion needed)
alias ls="lsd -1A"
alias ll="lsd -l"
alias la="lsd -la"
alias lt="lsd --tree"
alias cat="bat"

# Git
abbr -S -qq browse-pr="gh pr view --web"
alias isv='gh issue list | fzf-tmux --prompt "issue preview>" --preview "echo {} | awk '\''{print \$1}'\'' | xargs gh issue view -p" | xargs gh issue view'
alias prv='gh pr list | fzf-tmux --prompt "pr preview>" --preview "echo {} | awk '\''{print \$1}'\'' | xargs gh pr view -p" | xargs gh pr view'
abbr -S -qq browse="gh repo view --web"
alias brc='echo "$(gh repo view --json url --jq .url)/commit/$(git rev-parse HEAD)"'
abbr -S -qq gundo="git reset --soft HEAD~1"
abbr -S -qq grepush="git recommit && git push -f"
abbr -S -qq gsp="git stash && git pull && git stash pop"
abbr -S -qq gpgp="git pull && git push"
abbr -S -qq gpu="git pull"
abbr -S -qq rmswap='find . -type f -name "*.swp" -delete && find . -type f -name ".*.swp" -delete'
