#!/usr/bin/env bash
# Merge a flake update PR, or queue it with auto-merge when main requires checks.
#
# `gh pr merge --auto` merges immediately when the PR is CLEAN and otherwise
# enables auto-merge. Right after a force push GitHub reports UNKNOWN while it
# recomputes mergeability, and enabling auto-merge then fails on a repository
# that does not allow it. Concurrent update jobs also make the immediate merge
# fail with "Base branch was modified". Both cases used to be swallowed, which
# left every PR that lost the first attempt open forever.
set -euo pipefail

pr_number="$1"
max_attempts="${MERGE_MAX_ATTEMPTS:-10}"
retry_delay="${MERGE_RETRY_DELAY:-15}"

for attempt in $(seq 1 "$max_attempts"); do
  state=$(gh pr view "$pr_number" --json mergeStateStatus --jq '.mergeStateStatus')
  echo "PR #$pr_number merge state: $state (attempt $attempt/$max_attempts)"

  case "$state" in
  UNKNOWN)
    echo "Mergeability is still being computed"
    ;;
  DIRTY)
    echo "::error::PR #$pr_number conflicts with main. The next scheduled run recreates the branch from main."
    exit 1
    ;;
  *)
    if output=$(gh pr merge "$pr_number" --auto --squash 2>&1); then
      echo "$output"
      exit 0
    fi
    echo "$output"
    case "$output" in
    *"Base branch was modified"*)
      echo "main moved while merging; retrying"
      ;;
    *)
      echo "::error::Could not merge or enable auto-merge for PR #$pr_number: $output"
      exit 1
      ;;
    esac
    ;;
  esac

  if [ "$attempt" -lt "$max_attempts" ]; then
    # Jitter keeps the parallel matrix jobs from retrying in lockstep.
    sleep $((retry_delay + RANDOM % (retry_delay + 1)))
  fi
done

echo "::error::Gave up merging PR #$pr_number after $max_attempts attempts"
exit 1
