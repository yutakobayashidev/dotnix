# Codex reset announcement monitor

`tibo-reset-monitor` polls the [Codex Resets public API](https://codex-resets.com/api/openapi.json)
on B450M-Pro4 and posts new announcements to the existing `infra-info` Discord
webhook. The app is packaged in the personal NUR repository. It is separate
from [codex-limit-auto-reset](codex-limit-auto-reset.md): this monitor reports
public announcements and never consumes a personal reset credit or accesses
Codex authentication.

## Notifications

Each announcement produces a Discord embed with:

- A distinct title and color for a regular reset versus a banked reset credit.
- Announcement/observation time in `Asia/Tokyo` and `America/Los_Angeles`, with
  PST/PDT selected automatically by the timezone database.
- Original source text and a source link when available.
- A marker for observed resets without a confirmed announcement, and attribution
  to the unofficial Codex Resets tracker.

The timestamp is when the API says the event was announced or observed, not a
guarantee of the exact time every account's quota changed. Scheduled resets and
AI forecasts from `/api/v1/status` are not sent as completed resets. Role and
user mentions are disabled.

## Polling and persistence

The systemd timer runs after boot and then about every five minutes. The service
uses a dedicated dynamic user and `/var/lib/tibo-reset-monitor` for persistent
state. On the first successful complete scan it records existing IDs without
posting old announcements. Later runs fetch all cursor pages and send unseen
announcements oldest first, including entries added with older timestamps.

Delivered IDs survive reboots. Failed deliveries remain eligible for retry;
HTTP 429 responses defer later work according to Retry-After. Delivery waits for
Discord's acknowledgement before recording success. A crash or lost response
after Discord accepted a message can still cause a duplicate on retry; this is
not an exactly-once delivery guarantee.

The webhook URL comes from the existing sops secret through systemd
`LoadCredential`, not from the Nix store, command line, or an environment value.
Do not delete the state database to retry a delivery: a fresh database performs
the initial silent baseline again.

## Operations

```bash
systemctl status tibo-reset-monitor.timer
systemctl status tibo-reset-monitor.service
journalctl -u tibo-reset-monitor.service -n 50
sudo systemctl start tibo-reset-monitor.service
```

Inspect JSON journal events for baseline, delivery, rate limits, and failures.
Manual starts use the same persistent state and do not intentionally resend
already acknowledged announcements. Secrets and API response bodies are not
written to the service's logs.
