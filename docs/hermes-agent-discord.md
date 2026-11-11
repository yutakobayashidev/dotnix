# Hermes Agent Discord Setup

Hermes Agent runs on `UM790-Pro` as the `hermes-agent` microVM. Discord support
is managed by Nix and SOPS:

- Runtime config: `systems/nixos/services/hermes-agent/guest.nix`
- Encrypted bot token: `systems/nixos/services/hermes-agent/secrets.yaml`
- Allowed Discord user ID: `systems/nixos/services/hermes-agent/default.nix`
- Generated guest files: `/var/lib/hermes/.hermes/config.yaml` and
  `/var/lib/hermes/.hermes/.env`

## Discord Portal

Create a Discord application and bot in the Discord Developer Portal.

Required bot settings:

- Public Bot: on, unless using a manually constructed private invite URL
- Server Members Intent: on
- Message Content Intent: on

Invite URL format:

```text
https://discord.com/oauth2/authorize?client_id=YOUR_APP_ID&scope=bot+applications.commands&permissions=274878286912
```

The recommended permission integer includes view/send messages, embed links,
attachments, read history, thread replies, and reactions.

## Secrets

Do not paste the bot token into Nix files or temporary files. Store it in SOPS:

```bash
sops --set '["hermes-agent"]["discord-bot-token"] "YOUR_BOT_TOKEN"' systems/nixos/services/hermes-agent/secrets.yaml
```

The allowed user list is intentionally plain text in
`systems/nixos/services/hermes-agent/default.nix`:

```dotenv
DISCORD_ALLOWED_USERS=890908900520505354
```

Keep this to one Discord user ID if the bot should only respond to you.

## Apply

Deploy the host config:

```bash
nix run .#switch
```

Then verify the microVM service:

```bash
systemctl status microvm@hermes-agent.service
journalctl -u microvm@hermes-agent.service -f
```

## Behavior

The Nix-managed defaults are intentionally conservative:

- DMs respond to every allowed user message.
- Server channels require an `@mention`.
- Mentions create threads automatically.
- Threads continue without repeated mentions.
- Sessions are isolated per user in shared channels.
- History backfill is enabled for mentioned server-channel turns.
- The bot cannot ping `@everyone`, `@here`, or roles.

## OpenCode Go credential rotation

Hermes uses a dedicated service-account key in the Go workspace, independent
of the LiteLLM/dsh key. It is stored as `hermes-agent/opencode-go-key` in
`systems/nixos/services/hermes-agent/secrets.yaml` and rendered as
`OPENCODE_GO_API_KEY` in the host's `hermes-agent.env` sops template.

After updating that encrypted entry and deploying through Comin, restart
`microvm@hermes-agent.service` on UM790-Pro. Credentials are passed to the VM
at boot, so restarting only the guest's Hermes process does not refresh them.
The guest copies the credential environment into `/var/lib/hermes/.hermes/.env`.

The replacement key was verified on 2026-11-07 against the configured Go
fallback model, `deepseek-v4-pro`: response `OK`, `billing_source: go`, `cost: 0`.
Never commit plaintext keys or pass them as literal shell command arguments.

## Ori MCP

The same gateway connects to Ori with OAuth and supports MCP Events over
Tailnet-only HTTPS. See [Ori MCP configuration and login](hermes-ori-mcp.md).
