#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Try SOPS-encrypted key file first, fall back to plaintext for testing
if [[ -f "${SCRIPT_DIR}/luks-key.enc" ]]; then
  sops --decrypt "${SCRIPT_DIR}/luks-key.enc"
elif [[ -n ${LUKS_PASSWORD:-} ]]; then
  echo -n "$LUKS_PASSWORD"
else
  echo "ERROR: Set LUKS_PASSWORD env var or create terraform/luks-key.enc" >&2
  exit 1
fi
