#!/usr/bin/env zsh

# ========================================
# Environment variables
# ========================================
# zshenv is sourced on all invocations of the shell.
# It should contain commands to set the search path
# and other environment variables.

# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
