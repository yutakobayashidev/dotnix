#!/bin/bash

# Reference: https://gist.github.com/azu/cef84c98aeef832d43dfb640c7e321f5

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Difit CMUX
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🔍

CMUX="/Applications/cmux.app/Contents/Resources/bin/cmux"

# Get the working directory of the currently focused cmux pane
targetDir=$("$CMUX" sidebar-state | awk -F= '/^focused_cwd=/{print $2}')
if [[ -z $targetDir ]]; then
  echo "Error: Could not detect focused_cwd from cmux sidebar-state" >&2
  exit 1
fi

cd "$targetDir" || exit 1

# Provide immediate feedback so the user knows the script is running
"$CMUX" notify --title "Difit" --body "Loading diff: $targetDir"

echo "🔍 Detecting git state..."
currentBranch=$(git rev-parse --abbrev-ref HEAD)

# Detect default branch (origin/HEAD → origin/main → origin/master)
defaultBranch=$(git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null)
if [[ -z $defaultBranch ]]; then
  if git rev-parse --verify origin/main >/dev/null 2>&1; then
    defaultBranch="origin/main"
  elif git rev-parse --verify origin/master >/dev/null 2>&1; then
    defaultBranch="origin/master"
  fi
fi

# Kill any process using port 4966
kill_difit() {
  lsof -ti:4966 | xargs kill 2>/dev/null
}
trap kill_difit EXIT INT TERM

difitArgs=(--mode unified --no-open --clean --include-untracked --port 4966)

echo "🚀 Starting difit server..."
if [[ -z $defaultBranch ]] || [[ $currentBranch == "${defaultBranch#origin/}" ]]; then
  # On the default branch or no remote — diff working directory against HEAD
  difit working "${difitArgs[@]}" &
else
  mergeBase=$(git merge-base HEAD "$defaultBranch" 2>/dev/null)
  if [[ -z $mergeBase ]]; then
    # Fallback if merge-base cannot be determined
    difit working "${difitArgs[@]}" &
  else
    echo "🔀 Branch: $currentBranch (base: ${defaultBranch#origin/})"
    difit "$mergeBase" . "${difitArgs[@]}" &
  fi
fi

# Wait until the difit server is ready
while ! curl -s http://localhost:4966/ >/dev/null 2>&1; do
  sleep 0.5
done

# Open in a cmux browser split and get the surface ID
browserSurface=$("$CMUX" --json browser open-split "http://localhost:4966/" | grep -o '"ref" *: *"surface:[^"]*"' | head -1 | grep -o 'surface:[0-9]*')

if [[ -z $browserSurface ]]; then
  echo "Warning: Could not get browser surface ID, difit server running in background" >&2
  wait
  exit 0
fi

# Wait until the browser pane is closed, then shut down the server
while "$CMUX" surface-health 2>&1 | grep -q "$browserSurface"; do
  sleep 1
done

kill_difit
