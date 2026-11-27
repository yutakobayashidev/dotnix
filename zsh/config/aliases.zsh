#!/usr/bin/env zsh

# ========================================
# Abbreviations (zsh-abbr) & Aliases
# ========================================

# Keep fixed abbreviations in the shell without rewriting the user file.

# rebuild - unified via flake apps
abbr --session -f -qq rebuild="nix run ~/ghq/github.com/yutakobayashidev/dotnix#switch && source ~/.zshrc"

# Platform-specific abbreviations
if [[ "$(uname)" == "Darwin" ]]; then
  abbr --session -f -qq cpd="pwd | pbcopy"
else
  abbr --session -f -qq cpd="pwd | wl-copy"
fi

# AI tools
abbr --session -f -qq ct="atuin resume"
abbr --session -f -qq cl="claude"
abbr --session -f -qq cld="claude --dangerously-skip-permissions"
abbr --session -f -qq cldc="claude --dangerously-skip-permissions --continue"
abbr --session -f -qq clh="claude --dangerously-skip-permissions --model haiku"
abbr --session -f -qq clo="claude --dangerously-skip-permissions --model opus"
abbr --session -f -qq cls="claude --dangerously-skip-permissions --model sonnet"
abbr --session -f -qq oc="opencode"
abbr --session -f -qq cx="codex"
abbr --session -f -qq cxc="codex resume --last"
abbr --session -f -qq cxca="codex resume --last --all"
abbr --session -f -qq cxd="codex --dangerously-bypass-approvals-and-sandbox"
abbr --session -f -qq cxdc="codex --dangerously-bypass-approvals-and-sandbox resume --last"
abbr --session -f -qq cxp="codex-auth switch personal"
abbr --session -f -qq cxs="codex-auth switch school"
abbr --session -f -qq cxsw="codex-auth switch --skip-api"
abbr --session -f -qq cxb="codex-auth -"
abbr --session -f -qq pic="pi -c"
abbr --session -f -qq pir="pi -r"
abbr --session -f -qq ob="openbrief"
abbr --session -f -qq ca="cursor-agent"
abbr --session -f -qq nnn="course-cli"

# Docker
abbr --session -f -qq do="docker container"
abbr --session -f -qq dop="docker container ps"
abbr --session -f -qq dob="docker container build"
abbr --session -f -qq dor="docker container run --rm"
abbr --session -f -qq dox="docker container exec -it"

# Docker Compose
abbr --session -f -qq dc="docker compose"
abbr --session -f -qq dcu="docker compose up"
abbr --session -f -qq dcub="docker compose up --build"
abbr --session -f -qq dcd="docker compose down"
abbr --session -f -qq dcr="docker compose restart"

# Nix
abbr --session -f -qq ns="nix-shell"
abbr --session -f -qq ngc="nix-collect-garbage"
nrn() { nix run "nixpkgs#$1" "${@:2}"; }
abbr --session -f -qq ashiba="nfi github:yutakobayashidev/ashiba"
abbr --session -f -qq ndt="nfi github:the-nix-way/dev-templates"

abbr --session -f -qq p="pnpm"
abbr --session -f -qq gg="ghq get"

# Command replacements (keep as aliases — no visual expansion needed)
alias ls="eza -1A --icons --git"
alias ll="eza -l --icons --git"
alias la="eza -la --icons --git"
alias lt="eza --tree --icons --git-ignore"
alias lsf="eza -F -alh --no-user --time-style=long-iso --icons --git"
alias tree="eza --all --git-ignore --tree --icons --ignore-glob=.git"
alias cat="bat"

# Git
abbr --session -f -qq browse-pr="gh pr view --web"
alias isv='gh issue list | fzf-tmux --prompt "issue preview>" --preview "echo {} | awk '\''{print \$1}'\'' | xargs gh issue view -p" | xargs gh issue view'
alias prv='gh pr list | fzf-tmux --prompt "pr preview>" --preview "echo {} | awk '\''{print \$1}'\'' | xargs gh pr view -p" | xargs gh pr view'
abbr --session -f -qq browse="gh repo view --web"
alias brc='echo "$(gh repo view --json url --jq .url)/commit/$(git rev-parse HEAD)"'
abbr --session -f -qq gundo="git reset --soft HEAD~1"
abbr --session -f -qq grepush="git recommit && git push -f"
abbr --session -f -qq gsp="git stash && git pull && git stash pop"
abbr --session -f -qq gpgp="git pull && git push"
abbr --session -f -qq gpu="git pull"
abbr --session -f -qq rmswap='find . -type f -name "*.swp" -delete && find . -type f -name ".*.swp" -delete'
