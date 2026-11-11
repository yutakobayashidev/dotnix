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

## Declarative application login

The clients for Grafana, linkding, Immich, moe, Gitea, Nextcloud, Ori, and
Ori's ChatGPT and Muse connections are managed
in [`infra/pocket-id`](../infra/pocket-id/README.md). LiteLLM and n8n are excluded.
Client IDs and callback URLs are managed by OpenTofu; application settings are
managed by their NixOS service modules. Existing password login remains enabled.

`secrets/pocket-id-oidc.yaml` contains the static administration API key and the
application client secrets. Pocket ID receives its API key through a systemd credential;
application secrets are supplied through SOPS files or rendered templates, never
literal Nix store values. The matching API key and client-secret map are stored
in the repository's `POCKETID_API_TOKEN` and `POCKETID_CLIENT_SECRETS` Actions
secrets. Keep both copies in sync when rotating credentials.

On a new deployment, apply NixOS first to activate the API key, then run the
existing infrastructure workflow for target `pocket-id`: review `plan`, then
`apply` at the same revision. Subsequent client edits use that workflow too;
Comin applies application configuration changes. The two deployments are not
atomic, so retain password access during secret rotation.

Gitea authentication sources and Nextcloud provider entries are database-backed.
Their existing startup/setup scripts update the named `pocket-id` entry using
official CLIs; they do not add polling services. These database changes are not
undone merely by rolling back a NixOS generation.

### Existing accounts

- **Grafana:** registration and role synchronization remain disabled. The local
  administrator (user ID `1`) was explicitly linked in `user_auth` to Pocket ID
  subject `a3a3549f-6584-4c36-aa27-4492fc35420e`, using auth module
  `oauth_generic_oauth`, after a database backup and with Grafana stopped.
  Matching usernames is insufficient; email-based lookup remains disabled.
  First OIDC login synchronizes the old `admin` login name to `yuta` and the
  email to `hi@yutakobayashi.com`. The password, user ID and admin rights remain;
  subsequent local password login also uses `yuta`.
- **linkding:** existing accounts are matched by email. Automatic creation is
  disabled with `OIDC_CREATE_USER = False` in the upstream `custom.py` settings
  hook, supplied by a Nix package override (the setting has no environment
  variable in linkding). The `yuta` account uses `hi@yutakobayashi.com` and must
  exist before Pocket ID login. Additional users must be provisioned explicitly.
- **Immich / moe:** sign in with the existing password, then use account settings
  to link OAuth. Automatic registration is disabled. Check both web and mobile
  login. Their current storage-template settings are preserved in Nix; all
  system-settings changes now belong in configuration files rather than the UI.
- **Gitea:** choose Pocket ID and authenticate the existing account when asked
  to link it. Local credentials and existing two-factor authentication remain.
- **Nextcloud:** `preferred_username` must equal the existing internal username
  (`yuta`). Provisioning and group synchronization are disabled; local `root`
  password login remains available.

Before enabling OIDC, database snapshots were taken on B450M-Pro4 under
`/var/lib/oidc-migration-backups/2026-11-06` (root-only). These contain SQLite backups for
Pocket ID, Grafana, Gitea, and linkding, and PostgreSQL custom-format dumps for
Immich, moe, and Nextcloud. This directory survives root rollback through `/var/lib` persistence. It is on
the same host, not an off-host
disaster recovery backup. Restore only with the affected application stopped.

After deployment, check all service statuses and each login page, then complete
an interactive login and verify existing data and permissions before removing
any legacy login method. For host migration, preserve Pocket ID's database,
encryption key, public domain, and user/client IDs as well as OpenTofu state.

See the [upstream documentation](https://pocket-id.org/docs/setup/installation)
for registering passkeys and connecting OIDC clients.

## Ori browser login and MCP

Ori uses the fixed confidential client `ori` with PKCE and callback
`https://home.yutakobayashi.com/api/auth/callback`. Its existing owner data is
retained; only the configured Pocket ID issuer and subject can sign in.
The client secret is decrypted by Home Manager on UM790-Pro. Password login
and local account setup are removed by the application migration. Existing
browser sessions remain valid until logout or expiry.

MCP uses resource `https://home.yutakobayashi.com/mcp` and scope `ori:mcp`.
The application checks signed access tokens, issuer, audience, expiry, scope,
and the configured owner subject. ID tokens are not accepted as API tokens.
Internal Research and execution requests use separate, scoped credentials.

The existing `tunnel-client-personal-workspace` service remains the ChatGPT
transport. Its upstream URL uses the private HTTPS Tailnet route, supporting
OAuth discovery without publishing an additional ingress or opening ports.
In ChatGPT select the existing tunnel, OAuth authentication, and the fixed
client ID `ori-chatgpt`; retrieve its secret from SOPS key
`client-secrets/ori-chatgpt` in `secrets/pocket-id-oidc.yaml`. Do not paste the
secret into issues, logs, or this document. The registered callback is
`https://chatgpt.com/connector_platform_oauth_redirect`; verify that exact URI
in the connector settings. Complete Pocket ID passkey authentication there.

Muse uses the confidential client `ori-muse` with PKCE enabled and
`client_secret_basic` token authentication. Its only registered callback is
`https://agent.meta.ai/api/hatch/oauth/callback`, with no trailing slash.
Retrieve its secret from SOPS key `client-secrets/ori-muse` in
`secrets/pocket-id-oidc.yaml`; recovery requires a SOPS age key authorized for
that file. The secret is also synchronized to the `POCKETID_CLIENT_SECRETS`
Actions secret for subsequent OpenTofu deployments. No plaintext copy is stored.
No allowed user groups are specified, which grants All Users access in Pocket
ID. Ori still restricts access to its configured owner subject. The MCP manifest
grants this client user-delegated `ori:mcp` access, without client-credentials
access. Configure the connector with client ID `ori-muse` and this secret.

Claude Code and Codex can connect directly to the private HTTPS MCP URL from
the Tailnet using CIMD. The allowlist contains only the published metadata
URLs for Claude, Claude Code, and Codex. Claude's hosted service would need a
separate reachable transport; the OpenAI tunnel is not a generic Claude proxy.
ChatGPT's current CIMD document prefers `private_key_jwt`, which Pocket ID's
public-client-only CIMD implementation rejects, hence its separate fixed client.

Pocket ID UI configuration is disabled so Nix environment settings actually
control the CIMD allowlist. Existing settings were checked before switching;
user signup remains disabled. API permissions and grants use the committed
manifest and existing deployment workflow described in
[the infrastructure README](../infra/pocket-id/README.md), because the pinned
Pocket ID Terraform provider does not expose these API features.

Before the Ori migration, verified SQLite backups were taken at
`/home/yuta/.local/state/twitter-lite/backups/before-oidc-2026-11-07.sqlite`
on UM790-Pro and
`/var/lib/oidc-migration-backups/ori-2026-11-07/pocket-id-before-ori.db`
on B450M-Pro4. Restoring the old password-based Ori version requires restoring
its pre-migration database too, because the migration drops password columns.
