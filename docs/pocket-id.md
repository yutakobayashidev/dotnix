# Pocket ID

Pocket ID runs on B450M-Pro4 using the nixpkgs NixOS module and SQLite.
It listens on `127.0.0.1:1411`; its public URL is `https://id.yutakobayashi.com`.
The existing host Cloudflare Tunnel provides HTTPS access directly to Pocket ID.
No Traefik router or inbound firewall port is needed.

Configuration: `systems/nixos/services/pocket-id/default.nix`.
Cloudflare DNS: a proxied CNAME for `id.yutakobayashi.com` targeting
`3e1ff621-e8bf-47d1-b095-4b5c15eec63c.cfargotunnel.com`.

## Data and recovery

The default data directory `/var/lib/pocket-id` is covered by the host's existing
`/var/lib` persistence. The encryption key is stored in `secrets/pocket-id.yaml`
under `encryption-key` and loaded via systemd credentials. Back up both the data
directory (stop Pocket ID first for a consistent SQLite copy) and the encrypted
secret with a working SOPS decryption key. Restore both before starting the
service; do not generate a different encryption key for an existing database.

The initial admin is `yuta` (`hi@yutakobayashi.com`). Create the admin through the
local `/api/signup/setup` endpoint before exposing the tunnel hostname. Once an
account exists, setup is closed. The user registers a passkey at the public HTTPS
domain; passkeys are bound to that domain.

If passkey access is lost, Pocket ID provides `one-time-access-token yuta`.
Run it with the service's working directory and environment, including its
encryption credential. The generated login link is a secret and expires after
one hour; do not write it to logs or temporary files.

## Verification

```sh
systemctl status pocket-id
journalctl -u pocket-id -n 30
curl --fail https://id.yutakobayashi.com/.well-known/openid-configuration
```

See the [upstream documentation](https://pocket-id.org/docs/setup/installation)
for registering passkeys and connecting OIDC clients.
