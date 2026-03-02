#!/usr/bin/env zsh

# difit-cmux: Open difit in a cmux browser split for the focused pane's repo.
function difit-cmux() {
  setopt local_options pipe_fail no_unset

  local cmux_bin=""
  if (( $+commands[cmux] )); then
    cmux_bin="$(command -v cmux)"
  elif [[ -x "/Applications/cmux.app/Contents/Resources/bin/cmux" ]]; then
    cmux_bin="/Applications/cmux.app/Contents/Resources/bin/cmux"
  else
    echo "cmux not found" >&2
    return 1
  fi

  local required_cmd
  for required_cmd in difit git curl awk lsof; do
    if ! (( $+commands[$required_cmd] )); then
      echo "$required_cmd not found" >&2
      return 1
    fi
  done

  local target_dir
  target_dir="$("$cmux_bin" sidebar-state | awk -F= '/^focused_cwd=/{print $2}')"

  if [[ -z "$target_dir" || ! -d "$target_dir" ]]; then
    echo "Could not detect focused_cwd from cmux sidebar-state" >&2
    return 1
  fi

  (
    cd "$target_dir" || exit 1

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "Not a git repository: $target_dir" >&2
      exit 1
    fi

    "$cmux_bin" notify --title "Difit" --body "Loading diff: $target_dir"

    local current_branch
    local default_branch
    local merge_base

    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    default_branch="$(git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null || true)"

    if [[ -z "$default_branch" ]]; then
      if git rev-parse --verify origin/main >/dev/null 2>&1; then
        default_branch="origin/main"
      elif git rev-parse --verify origin/master >/dev/null 2>&1; then
        default_branch="origin/master"
      fi
    fi

    kill_difit() {
      lsof -ti:4966 | xargs kill 2>/dev/null || true
    }
    trap kill_difit EXIT INT TERM

    local difit_args=(--mode unified --no-open --clean --include-untracked --port 4966)

    if [[ -z "$default_branch" ]] || [[ "$current_branch" == "${default_branch#origin/}" ]] || [[ "$current_branch" == "HEAD" ]]; then
      difit working "${difit_args[@]}" &
    else
      merge_base="$(git merge-base HEAD "$default_branch" 2>/dev/null || true)"
      if [[ -z "$merge_base" ]]; then
        difit working "${difit_args[@]}" &
      else
        difit "$merge_base" . "${difit_args[@]}" &
      fi
    fi

    until curl -s http://localhost:4966/ >/dev/null 2>&1; do
      sleep 0.5
    done

    local browser_surface
    browser_surface="$("$cmux_bin" --json browser open-split "http://localhost:4966/" | grep -o '"ref" *: *"surface:[^"]*"' | head -1 | grep -o 'surface:[0-9]*')"

    if [[ -z "$browser_surface" ]]; then
      echo "Warning: Could not get browser surface ID, difit server running in background" >&2
      wait
      exit 0
    fi

    while "$cmux_bin" surface-health 2>&1 | grep -q "$browser_surface"; do
      sleep 1
    done

    kill_difit
  )
}
