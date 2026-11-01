#!/usr/bin/env bash
set -u

case "${1:-}" in
linux | darwin) platform=$1 ;;
*)
  echo "Usage: $0 linux|darwin" >&2
  exit 1
  ;;
esac

notify() {
  case "$platform" in
  linux)
    notify-send --app-name=comin "Comin approval required" \
      "An update is waiting. Review with comin status, then run comin confirmation accept."
    ;;
  darwin)
    /usr/bin/osascript -e 'display notification "An update is waiting. Review with comin status, then run comin confirmation accept." with title "Comin approval required"'
    ;;
  esac
}

declare -A last=([build]="" [deploy]="")
while true; do
  if status=$(comin status --json); then
    for phase in build deploy; do
      if pending=$(jq -er --arg phase "$phase" '
        .[$phase + "_confirmer"]
        | select(.submitted != null and .submitted != "" and .submitted != .confirmed)
        | .submitted
      ' <<<"$status"); then
        if [[ $pending != "${last[$phase]}" ]] && notify; then
          last[$phase]=$pending
        fi
      fi
    done
  fi
  sleep 30
done
