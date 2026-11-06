# OmniRoute

B450M-Pro4 runs the official OmniRoute 3.8.52 container, pinned by manifest digest.
Traefik serves `https://omniroute.home.yutakobayashi.com`; the OpenAI-compatible
base URL is `https://omniroute.home.yutakobayashi.com/v1`. The container's port
20128 is published only on host loopback port 8317. LiteLLM is removed.

## Configuration and credentials

`systems/nixos/services/omniroute/routing.json` declares the OpenCode Go models,
ChatGPT aliases, and the `deepseek-analyst` / `deepseek-inbox` priority fallback
chains used by Birdclaw. The bootstrap unit reconciles this configuration through
OmniRoute's management API. Individual model aliases select their named provider;
the old LiteLLM global default-fallback policy is not carried over. Use the two
explicit combos when automatic fallback is wanted.

The existing gateway key `sk-proxy` remains configured as `OMNIROUTE_API_KEY`.
OmniRoute treats this environment key as a management-capable key as well as an
inference key; this preserves the existing LiteLLM master-key access model.
`REQUIRE_API_KEY=true` enforces authentication. Dashboard login additionally uses
a generated password. Do not expose the gateway beyond its existing trusted
network boundary without replacing this shared key and updating its clients.

The OpenCode Go key and initial ChatGPT auth JSON remain SOPS-encrypted. Their
files move to the OmniRoute service directory without decrypting or re-encrypting
them. The YAML's existing `litellm/opencode-go-key` field is selected explicitly.
No provider credentials are placed in the Nix store or container environment.

On first boot, the bootstrap imports ChatGPT credentials only if no Codex
connection exists. It prefers `/var/lib/litellm/chatgpt/auth.json`, which may hold
newer rotated tokens, over the encrypted seed. Subsequent starts preserve
OmniRoute's refreshed tokens. Import errors fail the bootstrap unit. Importing
can rotate the OAuth refresh token, so never run LiteLLM against the same account
concurrently. The container unit conflicts with the old LiteLLM unit.

## Persistent state and recovery

- `/var/lib/omniroute`: SQLite database, provider credentials, settings and logs;
  mounted at `/app/data`, mode 0700, owned by container UID/GID 1000.
- `/var/lib/omniroute-secrets/environment`: generated `JWT_SECRET`,
  `API_KEY_SECRET`, and initial dashboard password; root-only, mode 0600.

Both paths live under the host's persistent `/var/lib`. Back up both together;
restoring the database without its encryption key can lose access to stored
credentials. Existing LiteLLM state is retained for inspection, not deleted.
To retrieve the initial dashboard password, read the root-only environment file
on B450M-Pro4 locally; do not copy it into issue bodies or logs. Dashboard password
changes are stored by OmniRoute and supersede `INITIAL_PASSWORD`.

A rollback to LiteLLM after OAuth import may need a fresh ChatGPT login: the old
refresh token can have been consumed. Do not restore an old token file over a
working OmniRoute connection. Stop the new gateway before attempting rollback.

## Deployment and verification

This change is deployed only after the PR is merged through the host's normal
Comin workflow. Terraform monitor changes require the usual plan/apply workflow;
the `moved` block preserves the existing Uptime Kuma monitor and history.

After deployment, check:

```bash
systemctl status podman-omniroute omniroute-bootstrap
journalctl -u omniroute-bootstrap -b
curl --fail https://omniroute.home.yutakobayashi.com/api/health/ping
curl --fail -H 'Authorization: Bearer sk-proxy' \
  https://omniroute.home.yutakobayashi.com/v1/models
```

The public health endpoint verifies process/database availability, not provider
credentials. Confirm both Birdclaw combo names are present, then make an intentional
inference request before relying on scheduled jobs. Client configurations outside
this repository must change their old LiteLLM base URL to the OmniRoute URL.

To reconcile settings after an operator change, restart `omniroute-bootstrap`.
For a failed initial Codex import, fix or refresh the credential and retry that
unit; do not delete an existing valid connection merely to repeat bootstrap.

Upstream references: [container deployment](https://github.com/cheaper-inference/OmniRoute/blob/v3.8.52/Dockerfile),
[environment contract](https://github.com/cheaper-inference/OmniRoute/blob/v3.8.52/.env.example),
[Codex import API](https://github.com/cheaper-inference/OmniRoute/blob/v3.8.52/src/app/api/oauth/codex/import/route.ts).
