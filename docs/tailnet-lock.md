# Tailnet Lock

## Status and recovery storage

Tailnet Lock was enabled on 2026-10-31 (JST). ThinkPad-X1-Carbon-Gen13 and
UM790-Pro are signing nodes, both running Tailscale 1.102.5. The three CI
credentials have separate trusted signing keys. Both signing nodes report no
peers blocked by missing signatures.

The Personal vault item `Tailnet Lock recovery 2026-10-31` in 1Password contains
three disablement secrets, the dedicated CI-export age identity, and each CI
credential's signing-key ID and expiry. Private local recovery files are in
`~/.local/state/tailnet-lock/2026-10-31/` (directory 0700, files 0600). Do not
copy these files into the repository or temporary directories.

The CI enrollment keys expire on **2027-01-29 around 01:18–01:21 JST**; rotate
and re-sign them before that date. The provider's API token has its own expiry
and is independent of the CI enrollment keys.

## Verification

Post-cutover checks on 2026-10-31:

- [Tailscale CI plan](https://github.com/yutakobayashidev/dotnix/actions/runs/41089503231): connection succeeds, no changes.
- [Uptime Kuma plan](https://github.com/yutakobayashidev/dotnix/actions/runs/41089513574): connection succeeds, no changes.
- [Gitea plan](https://github.com/yutakobayashidev/dotnix/actions/runs/41089508850): connection and plan succeed; unrelated drift was not applied.
- [kasumilog](https://github.com/zunoser/kasumilog/actions/runs/41089518268): join/ping succeeds; the existing collection failure (exit 1 without diagnostics) remains.
- [Snapshots](https://github.com/zunoser/299792457_/actions/runs/41089523586): join/ping succeeds; the existing Relay HTTP 502 during rendering remains.

[OAuth retirement](https://github.com/yutakobayashidev/dotnix/actions/runs/41089950064)
removed exactly the two unused clients without changing keys or ACLs.

Both signing nodes report the same five trusted keys and no filtered peers.
ThinkPad can still reach B450M-Pro4 directly. All three workflows are enabled.

## CI credentials

GitHub-hosted runners create new ephemeral nodes on every run. Under Tailnet
Lock, OAuth authentication alone does not sign those nodes. Use separate
pre-signed, reusable, ephemeral, pre-approved auth keys tagged `tag:ci` for:

| Repository                | Workflow                      | Secret scope                                             |
| ------------------------- | ----------------------------- | -------------------------------------------------------- |
| `yutakobayashidev/dotnix` | `infra-deploy.yaml`           | Repository `TS_AUTHKEY`                                  |
| `zunoser/kasumilog`       | `archive-collection-live.yml` | Environment `archive-collection-live`, `TS_AUTHKEY`      |
| `zunoser/299792457_`      | `snapshot.yml`                | Repository `TS_AUTHKEY` (Terraform instance `snapshots`) |

The Action's `statedir` is a sibling of the checkout, outside the repository and
temporary directories. It lives only for the hosted runner's lifetime. Never
upload or cache this directory. Retain the existing pinned Action version.

Signed auth keys contain a private signing key. Store them only in the intended
GitHub Secrets scope and private recovery storage, never in Git, logs, Terraform
state, or temporary files. Record each key's expiry and signing public key in
1Password so it can be rotated and revoked independently. Revoking or expiring
the auth key alone does not remove its signing key from Tailnet Lock trust.

Unsigned enrollment keys are managed by `tailscale_tailnet_key.ci` in
`infra/tailscale/keys.tf`, with one instance per repository. These raw keys live
in the existing encrypted OpenTofu state and are exposed only through the
sensitive `ci_auth_keys` output. The signed keys must not be written back to
state. The provider's API token is a separate bootstrap credential, already
configured in the deployment workflow as `TAILSCALE_API_KEY`.

For local signing without copying CI's provider credentials, dispatch the
existing deployment workflow with `target=tailscale-ci`, `mode=apply`, and
`ci_key_recipient` set to an age public recipient whose private identity is
stored outside the repository in mode-0600 persistent storage. The workflow
pipes the sensitive output directly into age and uploads only ciphertext as
`tailscale-ci-keys` (one-day retention). Download and decrypt privately on the
signing operator's machine. Never provide the age private identity to GitHub.
The default empty recipient produces no export.

The `tailscale-ci` target covers the three CI enrollment keys and their ACL
dependency. The previous OAuth clients and GitHub OAuth Secrets are retired. Review
its plan before applying. It avoids rotating the unrelated NixOS enrollment
key during CI key maintenance; use the ordinary `tailscale`
target for a complete infrastructure plan.

## Rotation and recovery

Before each CI auth key expires, use OpenTofu's `-replace` for the appropriate
`tailscale_tailnet_key.ci` instance (`dotnix`, `kasumilog`, or `snapshots`).
Terraform revokes the previous auth key as part of replacement. Sign the new
key on a trusted signing node using `tailscale lock sign file:<private-key-path>`,
update its GitHub Secret via stdin, and verify a fresh runner connects. Then remove
the previous key's trusted signing key with `tailscale lock remove`.
Track the signing key separately for each CI credential; do not remove a host's
signing key by mistake.

Automatic recreation of expired keys is disabled: replacing an unsigned key
without updating its signature and GitHub Secret would leave CI broken.
Coordinate each Terraform replacement with the affected workflow paused.

The Terraform-managed NixOS enrollment key expired on 2026-09-11. The SOPS
`tailscale-authkey` has not changed since June 14 and is also beyond the maximum
90-day lifetime. Updating enrollment credentials is a separate task: a full `tailscale` plan proposes recreating the Terraform key but
does not distribute the replacement to SOPS. Newly provisioned NixOS machines
need a valid enrollment method and then a node-key signature. A normal rebuild with existing Tailscale state does
not create a new node. Preserve signing-node state during reinstalls.

For a CI credential failure, keep the affected workflow paused while replacing
and signing its key. Retired OAuth credentials cannot be restored just by
reverting workflow YAML. For tailnet-wide emergency recovery, use a stored
disablement secret through the Tailscale admin console. Disabling and
re-enabling creates new recovery secrets; replace the saved recovery record.
Verify connectivity before resuming workflows.

## References

- [Tailnet Lock](https://tailscale.com/docs/features/tailnet-lock)
- [CLI and signed auth key security](https://tailscale.com/docs/reference/tailscale-cli/lock)
- [GitHub Action Tailnet Lock setup](https://github.com/tailscale/github-action#tailnet-lock)
