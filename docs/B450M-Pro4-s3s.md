# B450M-Pro4 s3s Workflow

[s3s](https://github.com/frozenpandaman/s3s) is a Splatoon 3 battle stats uploader that syncs match data to [stat.ink](https://stat.ink/).

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                       B450M-Pro4                             │
│                                                              │
│  ┌─────────────┐    ┌──────────────────┐                    │
│  │ sops secrets │───▶│ systemd service  │                    │
│  │ (encrypted)  │    │ ExecStartPre     │                    │
│  └─────────────┘    └────────┬─────────┘                    │
│                              │ seed if missing              │
│                              ▼                              │
│                       /var/lib/s3s/config.txt                │
│                              │                              │
│         ┌────────────────────┤                              │
│         │                    │                              │
│         ▼                    ▼                              │
│  ┌──────────────┐    ┌──────────────┐                       │
│  │nxapi-token   │    │ s3s.service  │                       │
│  │   .timer     │    │              │                       │
│  │ (every 1h)   │    │ -M 300 -r    │                       │
│  │      │       │    │ 30min restart│                       │
│  │      ▼       │    │ 24h max      │                       │
│  │nxapi-token   │    │              │                       │
│  │   .service   │    │ uploads to   │                       │
│  │ (oneshot)    │    │ stat.ink     │                       │
│  │ refreshes    │    └──────────────┘                       │
│  │ gtoken/      │                                          │
│  │ bullettoken  │                                          │
│  └──────────────┘                                          │
└──────────────────────────────────────────────────────────────┘
```

## Components

### 1. s3s Package

Provided by the `nur-packages` flake input as `pkgs.s3s`. It is built from `frozenpandaman/s3s@732c91e` with a patched `s3s.py` that reads `config.txt` from CWD instead of the app path. Wrapped with Python dependencies: `beautifulsoup4`, `mmh3`, `msgpack`, `packaging`, `requests`.

### 2. Secrets (SOPS)

| Secret              | Purpose                          |
| ------------------- | -------------------------------- |
| `s3s-api-key`       | stat.ink API key                 |
| `s3s-session-token` | Nintendo session token for nxapi |

Encrypted in `systems/nixos/services/s3s/secrets.yaml`.

### 3. Config Generation

- SOPS decrypts secrets → renders `s3s-config.txt` template as JSON
- `s3s.service` / `nxapi-token.service` seed `/var/lib/s3s/config.txt` from the template if the config file is missing
- `nxapi-token.service` mutates the config file in place as it refreshes `gtoken` / `bullettoken`

### 4. Token Refresh

`nxapi-token.timer` triggers every hour:

1. Reads `s3s-session-token` from SOPS secret path
2. Calls `nxapi util update-s3s-token` to refresh `gtoken`/`bullettoken` in the config file

### 5. Main Service

`s3s.service` runs `s3s -M 300 -r`:

- `-M 300`: Monitor mode, check every 300 seconds
- `-r`: Automatically upload new battles
- Restarts 30 minutes after exit (cooldown to avoid Nintendo rate limiting)
- Max runtime capped at 24 hours (`RuntimeMaxSec`)

### Dependencies

```
network-online.target
       │
       ▼
  nxapi-token.service  ──▶  s3s.service
       │
  nxapi-token.timer    (triggers nxapi-token.service every 1h)
```

## Service Management

```bash
# Check all service statuses
systemctl status s3s.service nxapi-token.service nxapi-token.timer

# View recent logs
journalctl -u s3s.service -f
journalctl -u nxapi-token.service -n 20

# Manual trigger
sudo systemctl restart s3s.service
sudo systemctl start nxapi-token.service

# Check config file
sudo stat /var/lib/s3s/config.txt
```

## Troubleshooting

### Token refresh failed

- Check if `s3s-session-token` exists in `secrets.yaml`
- Verify SOPS decryption works: `cat $(nix eval --raw .#nixosConfigurations.B450M-Pro4.config.sops.secrets."s3s-session-token".path)`

### s3s upload fails

- Token may have expired → manually trigger `nxapi-token.service`
- Check Nintendo account: session token may need rotation
- API key may have been rotated on stat.ink

### Stat.ink API Error

- The `-M` monitor mode auto-retries; a 30-minute cooldown prevents API rate limits
- If the error persists, check the stat.ink API key in `secrets.yaml`
