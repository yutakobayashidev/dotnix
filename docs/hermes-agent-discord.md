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
