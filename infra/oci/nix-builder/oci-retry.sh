#!/usr/bin/env bash
set -e
cd /home/yuta/ghq/github.com/yutakobayashidev/dotnix/infra/oci/nix-builder
export OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING=True
export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"

i=0
while true; do
  i=$((i + 1))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Attempt #$i"
  if nix develop "path:$(git rev-parse --show-toplevel)#default" --command tofu apply -auto-approve 2>&1; then
    echo ""
    echo "SUCCESS! nix-builder deployed"
    nix develop "path:$(git rev-parse --show-toplevel)#default" --command tofu output ip-address
    break
  fi
  echo "Retry in 60s..."
  sleep 60
done
