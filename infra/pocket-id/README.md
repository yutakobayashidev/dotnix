# Pocket ID clients

This root manages the Grafana, linkding, Immich, moe, Gitea, Nextcloud, Ori,
Ori ChatGPT, and Ori Muse OIDC clients. Application-side configuration lives
in the corresponding
`systems/nixos/services/` modules. LiteLLM and n8n are intentionally excluded.

The existing `Infra: Approved OpenTofu deploy` workflow accepts `pocket-id` as
a target. Run `plan`, review its result, and run `apply` against the same
revision. The workflow uses the dedicated `pocket-id-ci` shell because the
other infrastructure shell restricts providers to its Nix-built mirror.
The Pocket ID provider is downloaded using the committed dependency lock.

## Credentials and state

Required repository secrets:

- `POCKETID_API_TOKEN`: the API credential configured in Pocket ID.
- `POCKETID_CLIENT_SECRETS`: a JSON object with the keys `grafana`, `linkding`,
  `immich`, `moe`, `gitea`, `nextcloud`, `ori`, `ori-chatgpt`, and `ori-muse`.
  Values must match the application secrets managed by SOPS.
- Existing `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT`,
  `STATE_ENCRYPTION_PASSPHRASE`, and `TS_AUTHKEY` infrastructure credentials.

State and saved plans are encrypted by OpenTofu. State is stored in the
`homelab-infra-state` bucket under `pocket-id/terraform.tfstate`, with S3
locking enabled. Preserve the state encryption passphrase and Pocket ID
backup when moving the service to another host. Do not recreate clients or
change their IDs during a host migration.

For local operation, supply `POCKETID_API_TOKEN`, `TF_VAR_client_secrets`,
`TF_VAR_state_encryption_passphrase`, `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, and `R2_ENDPOINT` through the environment. Do not
write decrypted credentials or state to temporary files.

```sh
nix develop .#pocket-id-ci

tofu -chdir=infra/pocket-id init \
  -backend-config="endpoints={s3=\"$R2_ENDPOINT\"}"
tofu -chdir=infra/pocket-id plan
tofu -chdir=infra/pocket-id apply
```

Client secret changes must be applied to Pocket ID and the application's
SOPS secret together; changing only one side prevents login. Local login
remains available in the application configurations during migration.

## Ori MCP API access

`mcp.json` declares Ori's MCP resource identifier, permissions, and the
permissions available to allowed CIMD clients. The global CIMD URL allowlist
is configured separately in the Pocket ID NixOS module. Ori also validates
the access token's audience, scope, and owner subject before accepting it.
`clientPermissions` grants the fixed `ori-chatgpt` and `ori-muse` clients
user-delegated access to `ori:mcp`; it explicitly disables client-credentials access. These clients
are registered by OpenTofu before the reconciliation script runs.

Trozz/pocketid 2.5.0 does not manage API resources or their grants.
`sync-mcp.py` therefore reconciles this manifest after OpenTofu in the same
deployment workflow. These API settings are **not in OpenTofu state**. Plan
mode only reads and reports differences. Apply finds the API by its immutable
resource identifier, creates it if absent, updates changed settings, and
reads it again to verify the result. Repeated apply does not issue writes
when settings match. No background service or timer is involved.

```sh
nix develop .#pocket-id-ci --command python3 infra/pocket-id/sync-mcp.py plan
nix develop .#pocket-id-ci --command python3 infra/pocket-id/sync-mcp.py apply
nix develop .#pocket-id-ci --command python3 -m unittest discover -s infra/pocket-id -p 'test_*.py'
```

Both deployment commands read `POCKETID_API_TOKEN` from the environment.
The manifest owns the entire permission list and CIMD grant for this API;
out-of-band changes are reported by plan and reconciled by apply. Changing
the resource URI creates a new API and leaves the old API for an explicit
migration/removal. To disable CIMD access, set `cimdPermissions` to `[]` and
apply before removing this manifest or its workflow invocation.
To revoke a managed fixed client's access, set its `clientPermissions` entry
to `[]` and apply before removing the entry. Unlisted fixed clients are not
modified by this script.
