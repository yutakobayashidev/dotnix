#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

mkdir -p persist/etc/ssh
umask 0177
sops --extract '["ssh_host_ed25519_key"]' --decrypt \
  "$SCRIPT_DIR/oci_secrets.yaml" >persist/etc/ssh/ssh_host_ed25519_key
