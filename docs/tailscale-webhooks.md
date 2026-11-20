# Tailscale webhooks

`infra/tailscale/webhooks.tf` sends device misconfiguration and tailnet management
events directly to Discord `infra-info`, using Tailscale's native Discord payload.
This includes node creation/deletion (including ephemeral CI nodes), approval,
Tailnet Lock signatures, key expiry, policy updates, and user changes.
Both event categories are subscribed, including future events Tailscale adds to them.

The endpoint reuses Alertmanager's `discord-infra-info` value in
`secrets/alertmanager.yaml`. The deployment workflow reads the same URL from the
repository secret `DISCORD_INFRA_INFO_WEBHOOK_URL`; it does not use the separate
Uptime Kuma `DISCORD_WEBHOOK_URL`. After rotating the Alertmanager webhook,
resynchronize the GitHub secret and apply the Tailscale plan:

```bash
set -o pipefail
sops decrypt --extract '["discord-infra-info"]' secrets/alertmanager.yaml \
  | gh secret set DISCORD_INFRA_INFO_WEBHOOK_URL --repo yutakobayashidev/dotnix
```

Do not print the decrypted URL or save it to a temporary file. The URL and
Tailscale signing secret are stored in the existing encrypted OpenTofu state.

Use `Infra: Approved OpenTofu deploy` with target `tailscale-webhook` in plan mode
before applying the same main revision. This target plans and applies only
`tailscale_webhook.infra_info`, leaving enrollment keys and other resources alone.
After a successful apply it verifies the endpoint configuration through the
Tailscale API and queues a test event. Confirm receipt in Discord `infra-info`.

The ordinary `tailscale` target still plans the complete root. Review unrelated drift, especially the expired NixOS enrollment key
documented in [Tailnet Lock](tailnet-lock.md), before any full apply. The
`tailscale-ci` target only maintains CI keys and does not create this webhook.
After applying, use **Test** on the endpoint in the Tailscale Webhooks admin page
and confirm the event arrives in `infra-info`.

Reference: [Tailscale webhooks](https://tailscale.com/docs/features/webhooks).
