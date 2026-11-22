# Vultr Mastodon VPS

OpenTofu stack for the `vultr-fedi` NixOS machine that is planned to host
Mastodon (`fedi.yutakobayashi.com`). It is a draft; the migration is tracked in
yutakobayashidev/dotnix#2405.

The stack creates a Vultr instance in Tokyo from a stock image only to boot the
nixos-anywhere kexec installer, then installs
`nixosConfigurations.vultr-fedi` with its disko partition layout.

The host exposes no public TCP ports. HTTP(S) reaches nginx through Cloudflare
Tunnel, and administration goes through Tailscale SSH. Because SSH to the
public IP stops working once NixOS boots, the stack uses only the
nixos-anywhere `install` module and leaves later deployments to comin. To
reinstall, replace the instance with `tofu apply -replace=vultr_instance.fedi`.

## Local files

Create `terraform.tfvars` from `terraform.tfvars.example`.

Create a SOPS-encrypted `vultr_secrets.yaml` containing the Vultr API key and a
pre-generated SSH host key:

```yaml
api_key: ...
ssh_host_ed25519_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

`decrypt-ssh-secret.sh` places the SSH host key into `/etc/ssh` before the
first boot so that sops-nix has a stable age identity. Add the age recipient
derived from `ssh_host_ed25519_key.pub` to:

- `systems/nixos/vultr-fedi/secrets.yaml`, the host's own secrets, and
- `secrets/default.yaml`, which holds the shared Tailscale auth key.

Neither local file should be committed.

## Persistent key sources

Keep the source keys outside the repository:

```text
~/.local/share/dotnix/vultr-fedi/ssh_host_ed25519_key
~/.local/share/dotnix/vultr-fedi/ssh_host_ed25519_key.pub
~/.local/share/dotnix/vultr-fedi/vultr_secrets.yaml
```

Back up this directory securely. Losing it prevents recovery of the injected
SSH host identity, and with it access to the host's SOPS secrets.

## Host secrets

`systems/nixos/vultr-fedi/secrets.yaml` needs these keys:

| Key                                                              | Source                                                                                                                          |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `mastodon/secret-key-base`                                       | `SECRET_KEY_BASE` in the current `.env.production`                                                                              |
| `mastodon/vapid-public-key`, `mastodon/vapid-private-key`        | `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`                                                                                         |
| `mastodon/active-record-encryption-*`                            | the three `ACTIVE_RECORD_ENCRYPTION_*` values                                                                                   |
| `mastodon/smtp-password`                                         | tofu-configuration output `mastodon_email_sending_token`                                                                        |
| `mastodon/s3-env`                                                | env file with `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `S3_ENDPOINT` from tofu-configuration's `mastodon_r2_*` outputs |
| `cloudflared-tunnel`                                             | credentials JSON of the host's Cloudflare Tunnel                                                                                |
| `cloudflare-origin/certificate`, `cloudflare-origin/private-key` | Cloudflare Origin CA certificate for `fedi.yutakobayashi.com`                                                                   |

## Migration outline

1. Dump the current database with `pg_dump -Fc`.
2. Run `tofu apply` here to create and install the host.
3. Restore the dump into the `mastodon` database. Mastodon runs the
   4.5 → 4.7 migrations when the service starts, so try this on a staging copy
   first.
4. Create the tunnel and move the `fedi` DNS record to it in
   tofu-configuration.
5. Check login, posting, federation, and mail, then stop the old VPS.
