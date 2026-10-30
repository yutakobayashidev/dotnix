# Tailnet Lock

## Rollout status

The workflow migration is prepared; Tailnet Lock has not yet been enabled.
Do not deploy the auth-key workflow until its `TS_AUTHKEY` secret is provisioned.
Signing nodes are planned to be ThinkPad-X1-Carbon-Gen13 and UM790-Pro.
Both report Tailscale 1.102.5.

The bootstrap configuration was published in `00be146f`. The first
[CI plan](https://github.com/yutakobayashidev/dotnix/actions/runs/41085762764)
failed because the existing `TAILSCALE_API_KEY` returned HTTP 401. No apply
or Lock initialization has run. Refresh the provider credential before retrying.
The dedicated export identity is stored in
`~/.local/state/tailnet-lock/2026-10-31/ci-export.agekey` (0600) and in the
Personal vault item `Tailnet Lock recovery 2026-10-31` in 1Password.

## CI credentials

GitHub-hosted runners create new ephemeral nodes on every run. Under Tailnet
Lock, OAuth authentication alone does not sign those nodes. Use separate
pre-signed, reusable, ephemeral, pre-approved auth keys tagged `tag:ci` for:

| Repository | Workflow | Secret scope |
| --- | --- | --- |
| `yutakobayashidev/dotnix` | `infra-deploy.yaml` | Repository `TS_AUTHKEY` |
| `zunoser/kasumilog` | `archive-collection-live.yml` | Environment `archive-collection-live`, `TS_AUTHKEY` |

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
existing deployment workflow with `target=tailscale`, `mode=apply`, and
`ci_key_recipient` set to an age public recipient whose private identity is
stored outside the repository in mode-0600 persistent storage. The workflow
pipes the sensitive output directly into age and uploads only ciphertext as
`tailscale-ci-keys` (one-day retention). Download and decrypt privately on the
signing operator's machine. Never provide the age private identity to GitHub.
The default empty recipient produces no export.

## Cutover

1. Check all tailnet clients meet Tailscale's minimum version (1.46.1), verify
   both signing nodes are accessible, and confirm device approval is disabled.
   Verify recovery-secret storage is writable before initialization.
2. Prepare both workflow changes and validate them. Apply the Terraform CI key
   resources using the existing OAuth workflow, then export the keys encrypted
   to the operator. Record current workflow enablement states; disable the two affected workflows and let active runs
   finish before changing the tailnet.
3. Collect the two `tlpub:` public keys with `tailscale lock status`. Initialize
   from one of those nodes with both keys and `--gen-disablements=3`. Capture
   the output directly in a mode-0600 persistent file outside the repository,
   and store the disablement secrets in 1Password. Never print them in agent
   logs. Verify both nodes report the same trusted keys.
4. Decrypt the exported keys privately (never print them in logs). Sign each
   key on a trusted node with
   `tailscale lock sign file:<private-auth-key-path>`, and save the signed output
   privately. Upload it via stdin to the correct GitHub Secret scope. Deploy
   both workflow changes, restore the recorded workflow enablement states,
   then run dotnix plans and a bounded kasumilog live collection.

Confirm the Tailscale connection/ping steps succeed and no intended peer is
locked out. Distinguish pre-existing application failures from connectivity
failures. Once validated, retire unused OAuth credentials through the existing
Terraform resources and remove their unused GitHub Secrets.

## Rotation and recovery

Before each CI auth key expires, use OpenTofu's `-replace` for the appropriate
`tailscale_tailnet_key.ci["dotnix"]` or `["kasumilog"]` instance and sign the replacement, update its
GitHub Secret, and verify a fresh runner connects. Then revoke the old auth key
and remove its corresponding trusted signing key with `tailscale lock remove`.
Track the signing key separately for each CI credential; do not remove a host's
signing key by mistake.

Automatic recreation of expired keys is disabled: replacing an unsigned key
without updating its signature and GitHub Secret would leave CI broken.
Coordinate each Terraform replacement with the affected workflow paused.

New NixOS machines still using `tailscale-authkey` need their node keys signed
after initial enrollment. A normal rebuild with existing Tailscale state does
not create a new node. Preserve signing-node state during reinstalls.

If cutover fails, use a stored disablement secret through the Tailscale admin
console to disable Tailnet Lock, restore the previous OAuth workflow revisions
and recorded workflow states, then verify connectivity. Do not resume jobs with
unprovisioned credentials. Disabling and re-enabling creates new recovery
secrets; replace the saved recovery record each time.

## References

- [Tailnet Lock](https://tailscale.com/docs/features/tailnet-lock)
- [CLI and signed auth key security](https://tailscale.com/docs/reference/tailscale-cli/lock)
- [GitHub Action Tailnet Lock setup](https://github.com/tailscale/github-action#tailnet-lock)
