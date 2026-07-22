#!/usr/bin/env bash

set -u

# Drain Codex's hook payload. The focus target is inherited from the shell that
# launched Codex, so the payload itself is not needed here.
cat >/dev/null

if [ "${HERDR_ENV:-}" = 1 ] || [ -z "${NIRI_SOCKET:-}" ]; then
  exit 0
fi

window_id=${CODEX_NIRI_WINDOW_ID:-}
case "$window_id" in
'' | *[!0-9]*) exit 0 ;;
esac

"${NIRI_BIN:-niri}" msg action focus-window --id "$window_id" >/dev/null 2>&1 || true
