#!/usr/bin/env zsh
set -euo pipefail

F=$(jq -r '.tool_input.file_path // empty')
[[ "$F" == "$CLAUDE_PROJECT_DIR"/*.md ]] || exit 0

B=$(obsidian backlinks path="${F#$CLAUDE_PROJECT_DIR/}" 2>/dev/null | grep -vE 'Loading|Error:') || true
[[ -n "$B" ]] || exit 0

jq -n --arg b "$B" '{hookSpecificOutput: {hookEventName:"PreToolUse", additionalContext:("Backlinks: " + $b)}}'
