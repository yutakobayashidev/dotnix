# Hermes and Ori MCP

The UM790-Pro Hermes microVM connects to `https://home.yutakobayashi.com/mcp`
through the Tailnet. Its declarative `mcp_servers.ori` configuration enables
OAuth and MCP Events and embeds the fixed client ID `ori-hermes`.

## Authentication

OpenTofu registers a confidential Pocket ID client with PKCE, All Users access
(no group restrictions), and the exact callback `http://127.0.0.1:27890/callback`.
The MCP manifest grants user-delegated `ori:mcp` access. Ori still checks the
configured owner subject. Client-credentials grants are not enabled.

The client secret is encrypted at `client-secrets/ori-hermes` in
`secrets/pocket-id-oidc.yaml`. The host's SOPS template passes it to the guest
through systemd credentials as `ORI_MCP_CLIENT_SECRET`. Hermes config contains
only an environment-variable reference. Recover the secret with an authorized
SOPS age key; keep `POCKETID_CLIENT_SECRETS` in Actions synchronized on rotation.

After deployment, run `hermes mcp login ori` as the guest's `hermes` user with
`HOME=/var/lib/hermes`. Open the authorization URL, complete Pocket ID login,
and paste the final redirect URL at the command's prompt (the loopback URL may
show a connection error in the browser). OAuth tokens remain in the persistent
`/var/lib/hermes/.hermes/mcp-tokens` directory. Never commit them. Restart the
gateway after successful login, then verify Ori tool discovery.

## Tailnet event delivery

Hermes listens on guest TCP 8644, forwarded to host loopback TCP 18644.
`hermes-mcp-events-serve.service` adds only `/webhooks` to the existing Tailscale
Serve HTTPS host `um790-pro.tail29d068.ts.net`; its existing root route is retained.
This uses Serve, not Funnel, and does not expose the receiver to the internet.
The SDK setting is named `public_url`, but points to this Tailnet-only HTTPS URL.

Ori's web process and worker receive `WORKSPACE_MCP_WEBHOOK_TAILNET_DESTINATIONS`,
which permits that exact HTTPS origin only at UM790-Pro's pinned Tailscale IPv4
and IPv6 addresses. Other private destinations remain blocked. Update the pins
if the node is re-enrolled. DNS is checked on every connection; TLS verification,
webhook signatures, bounded responses, and redirect rejection remain enabled.

Enabling events exposes `list_event_types`, `subscribe_event`, and
`unsubscribe_event`. No subscriptions are created by deployment. Each subscription
needs its event arguments, instructions, and delivery destination selected by the
owner. Event runs require the gateway to be running and valid OAuth tokens.

References: [Hermes MCP documentation](https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp)
and [Ori callback policy](https://github.com/yutakobayashidev/ori/blob/main/docs/beeper-mcp-events.md).
