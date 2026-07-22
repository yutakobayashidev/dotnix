codex() {
  if [[ ${HERDR_ENV:-} == 1 ]]; then
    CODEX_NIRI_WINDOW_ID= command codex "$@"
    return
  fi

  local window_id=""
  if [[ -n ${NIRI_SOCKET:-} ]] && (( $+commands[niri] && $+commands[jq] )); then
    window_id=$(niri msg -j focused-window 2>/dev/null | jq -r \
      'select(.app_id == "com.mitchellh.ghostty") | .id // empty')
  fi

  if [[ $window_id == <-> ]]; then
    CODEX_NIRI_WINDOW_ID=$window_id command codex "$@"
  else
    CODEX_NIRI_WINDOW_ID= command codex "$@"
  fi
}
