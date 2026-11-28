#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

mkdir -p etc/ssh
umask 0177
sops --extract '["ssh_host_ed25519_key"]' --decrypt \
  "$SCRIPT_DIR/vultr_secrets.yaml" >etc/ssh/ssh_host_ed25519_key
