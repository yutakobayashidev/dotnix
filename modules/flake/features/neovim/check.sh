#!/usr/bin/env bash
# Neovim config compilation and plugin restoration script
# Usage: nvim-restore.sh <nvim-dotfiles-dir> <lazy-dir> <nvim-bin>

set -e

NVIM_DOTFILES_DIR="$1"
LAZY_DIR="${2:-$HOME/.local/share/nvim/lazy}"
NVIM_BIN="${3:-nvim}"
export NVIM_DOTFILES_DIR

LAZY_LOCK="$NVIM_DOTFILES_DIR/lazy-lock.json"
LAZY_LOCK_TIMESTAMP="$LAZY_DIR/.lazy-lock-timestamp"
FENNEL_ROOT="$NVIM_DOTFILES_DIR/fnl"
GENERATED_ROOT="$NVIM_DOTFILES_DIR/lua/rc"

[[ -f "$NVIM_DOTFILES_DIR/init.fnl" ]]
[[ -f "$FENNEL_ROOT/rc/init.fnl" ]]

echo "Compiling Neovim Fennel configuration..."
"$NVIM_BIN" \
  --headless \
  --cmd 'lua vim.opt.runtimepath:prepend(vim.env.NVIM_DOTFILES_DIR)' \
  -u "$NVIM_DOTFILES_DIR/init.lua" \
  "+NfnlCompileAllFiles" \
  '+if v:errmsg != "" | cquit | endif' \
  +qa

[[ -f "$GENERATED_ROOT/init.lua" ]]
grep -q '^-- \[nfnl\] ' "$NVIM_DOTFILES_DIR/init.lua"
grep -q '^-- \[nfnl\] ' "$GENERATED_ROOT/init.lua"

if [[ -f $LAZY_LOCK ]]; then
  echo "Restoring Neovim plugins from lazy-lock.json..."
  "$NVIM_BIN" \
    --headless \
    --cmd 'lua vim.opt.runtimepath:prepend(vim.env.NVIM_DOTFILES_DIR)' \
    -u "$NVIM_DOTFILES_DIR/init.lua" \
    "+Lazy! restore" \
    '+if v:errmsg != "" | cquit | endif' \
    +qa
  mkdir -p "$LAZY_DIR"
  touch "$LAZY_LOCK_TIMESTAMP"
  echo "Neovim plugins restored."
fi
