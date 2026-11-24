# Octo STS

B450M-Pro4 runs a self-hosted [Octo STS](https://github.com/octo-sts/app) at
`https://sts.yutakobayashi.com`. It exchanges a GitHub Actions OIDC token for a
short-lived token of the `yuta-octo-sts` GitHub App (App ID 5900527). Each
repository decides who may get a token, and with which permissions, in a trust
policy on its default branch. Workflows therefore need no App private key in
GitHub Secrets. This follows 10X's setup:
<https://product.10x.co.jp/entry/2026/01/31/100000>.

| Part            | Where                                                                                                        |
| --------------- | ------------------------------------------------------------------------------------------------------------ |
| Service         | `systems/nixos/services/octo-sts` (podman container, image pinned by digest, listening on `127.0.0.1:18792`) |
| App private key | `secrets/octo-sts.yaml` (sops, `b450m` and `thinkpad-home`)                                                  |
| Public endpoint | Cloudflare Tunnel ingress; the DNS record is in yutakobayashidev/tofu-configuration                          |
| Logs            | journald of `podman-octo-sts.service`, shipped to Loki                                                       |

## App permissions

The App has Contents and Pull requests write, plus Metadata read, and is
installed only on the repositories that use it. A repository's trust policy
can request any of the App's permissions, so the App never gets strong
permissions such as Administration: those stay with the KMS-signed Apps in
tofu-configuration.

## Trust policies

Policies live in `.github/chainguard/<identity>.sts.yaml` of the target
repository and are read from its default branch, so a pull request cannot
grant itself access. GitHub issues the immutable subject, with numeric owner
and repository IDs, so match it rather than the name-based form:

```yaml
issuer: https://token.actions.githubusercontent.com
subject: repo:yutakobayashidev@91340399/dotnix@<repository_id>:ref:refs/heads/main
claim_pattern:
  job_workflow_ref: yutakobayashidev/dotnix/\.github/workflows/<workflow>\.yml@refs/heads/main

permissions:
  contents: write
  pull_requests: write
```

Request a token with the pinned `octo-sts/action`, setting
`domain: sts.yutakobayashi.com`, `scope: ${{ github.repository }}`, and
`identity: <identity>`.

Octo STS caches trust policies. After changing one, restart the service if
the new policy must apply immediately:
`systemctl restart podman-octo-sts.service`.

## Policies in dotnix

| Identity         | Workflow (job)                                                                                | Permissions                        |
| ---------------- | --------------------------------------------------------------------------------------------- | ---------------------------------- |
| `flake-update`   | `_update-flake-reusable.yaml`, called by `update-flake.yaml` and `update-flake-frequent.yaml` | Contents and Pull requests write   |
| `overlay-update` | `update-overlays.yaml`                                                                        | Contents and Pull requests write   |
| `auto-rebase`    | `auto-rebase.yaml`                                                                            | Contents write, Pull requests read |

Each workflow gets its token through `.github/actions/setup-git-bot` with
`identity: <identity>`, and needs `id-token: write` on the job. The token
belongs to `yuta-octo-sts[bot]`, so the pull requests it opens and the pushes
it makes still trigger CI, which `GITHUB_TOKEN` would not.

## Rotating the App key

1. Generate a new private key in the App settings.
2. Replace `github-app-private-key` in `secrets/octo-sts.yaml` with
   `sops secrets/octo-sts.yaml` and deploy.
3. Delete the old key in the App settings.
