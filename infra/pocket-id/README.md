# Pocket ID clients

This root manages the Grafana, linkding, Immich, moe, Gitea, and Nextcloud
OIDC clients. Application-side configuration lives in the corresponding
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
  `immich`, `moe`, `gitea`, and `nextcloud`. Values must match the application
  secrets managed by SOPS.
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
