# Home Assistant and Nature Remo Lapis

B450M-Pro4 runs native Home Assistant and Matter.js Server. Lapis and the
server must share the home LAN. This follows the
[natsukium configuration](https://github.com/natsukium/dotfiles/tree/6cebb564ec31f4072db323b36a3b8455c9004322/systems/nixos/services/home-assistant),
with Matter added, Traefik retained, and Restic initially stored locally.

| Data                                         | Storage                           | Retention                      |
| -------------------------------------------- | --------------------------------- | ------------------------------ |
| Entity state changes and Activity            | Recorder, SQLite                  | 14 days                        |
| Supported numeric sensor statistics          | Recorder                          | HA long-term statistics        |
| Sampled sensor and appliance state           | VictoriaMetrics, every 60 seconds | 1 year                         |
| Service diagnostics                          | systemd journal                   | Existing host journal policy   |
| HA configuration, Recorder and Matter fabric | Restic                            | 14 daily, 8 weekly, 12 monthly |

Existing Prometheus remains responsible for machine monitoring. Grafana has a
separate **Home Assistant** data source for VictoriaMetrics. Start with
`{__name__=~"homeassistant_.*"}` in Explore, then select the actual temperature
and humidity metrics and entity labels; entity IDs are assigned after pairing.

Neither a scrape nor a reported climate state proves that an IR appliance
physically obeyed a command. Recorder/Activity are not a complete command audit
trail. This configuration does not add a custom command logger, Cloud API
polling, HACS, or InfluxDB. Verify which Lapis controls and sensors appear over
Matter before adding another integration.

## Apply and pair

1. Build and apply on B450M-Pro4 with `nix run .#switch`.
2. Open `http://192.168.0.5:8123` for initial HA account/network setup.
   HA 2026.8+ manages HTTP settings in its UI. Under Settings → System → Network
   → HTTP, verify port 8123, enable X-Forwarded-For, and trust only `127.0.0.1`
   and `::1` for the local Traefik proxy. Existing migrated HTTP settings are
   retained in `.storage`. Then use `https://ha.home.yutakobayashi.com`.
3. Add the Matter integration using the existing server URL
   `ws://127.0.0.1:5580/ws` (disable installation of an HA OS server app).
4. Use the Home Assistant Companion app on a phone on the same LAN and the
   pairing code issued by the Nature Remo app to commission Lapis. If already
   paired elsewhere, use its sharing/new commissioning code.
5. Verify temperature, humidity, AC controls, state history, and recovery after
   service restart. Test local control during an Internet outage separately;
   a successful API call alone does not establish this.

Matter Server uses `wlp2s0f0u5`, the observed B450M-Pro4 home Wi-Fi interface.
Update `matter.nix` if this changes. mDNS UDP 5353 and IPv6 UDP on this interface
are permitted; Matter uses ephemeral ports, so opening only UDP 5540 is
insufficient. This trusts IPv6 UDP entering the home LAN interface, including
routed traffic: keep the upstream router's Internet ingress firewall enabled.
TCP filtering remains in effect. WebSocket 5580 binds only to loopback.
No server Bluetooth adapter or Thread border router is needed for normal Lapis
Wi-Fi operation. NixOS native Matter is outside HA's officially supported HA OS
server installation.

## Enable metrics collection

Create a dedicated HA user and a long-lived access token from that user's
profile. On B450M-Pro4, save it as the sole line in
`/var/lib/home-assistant-secrets/prometheus-token` using `sudoedit`, then:

```sh
sudo chmod 600 /var/lib/home-assistant-secrets/prometheus-token
sudo systemctl start victoriametrics
```

Do not put tokens in Nix expressions, shell command arguments, Git, or `/tmp`.
The parent directory is root-only, and systemd passes the token with
`LoadCredential`. VictoriaMetrics is skipped until this file exists. Its API
binds only to `127.0.0.1:8428`; HA's metrics endpoint still requires authentication.

Check `http://127.0.0.1:8428/targets` on the server, or query
`up{job="home-assistant"}` through Grafana; it must become 1. The filter exports
sensors, binary sensors, climates, lights and switches. Narrow it to observed
entity IDs if unrelated sensors are added later.

## Local backup

Restic stores encrypted snapshots at `/srv/bulk/backups/home-assistant` daily
at 03:00 with up to 45 minutes jitter. The service requires `/srv/bulk` to be
mounted. This is a separate disk on the same machine, not an off-site backup.

Create the repository password once, directly at its persistent destination:

```sh
sudo sh -c 'umask 077; test ! -e /var/lib/home-assistant-secrets/restic-password && openssl rand -base64 48 > /var/lib/home-assistant-secrets/restic-password'
sudo systemctl start restic-backups-home-assistant
sudo restic-home-assistant snapshots
sudo restic-home-assistant check
```

Keep a separate recovery copy of this password in a password manager. Losing it
makes the repository unreadable. The timer skips backups until the password is
present. Secrets remain outside Git and the Nix store. `/var/lib` is already
persistent on this impermanent host.

The prepare step uses SQLite's online `.backup` API as `hass`, excluding the
live DB/WAL/SHM from Restic. Matter Server is briefly stopped while copying its
fabric state, then restarted before Restic uploads files. Scheduled controls
may be interrupted during this short pause. Failure to copy the state fails
the backup. Staging lives in `/var/lib/home-assistant-backup` and is cleaned
after the backup, including failures. HA `.storage` is included; caches, logs,
TTS files and HA's own backup archives are excluded.

VictoriaMetrics data is persistent but is **not** included in this backup.
Restoring HA recovers Recorder history, not the one-year metrics archive.

### Restore

First inspect a snapshot without overwriting the live services:

```sh
sudo install -d -m 700 /var/lib/home-assistant-restore
sudo restic-home-assistant restore latest --target /var/lib/home-assistant-restore
```

On a replacement machine, apply Nix first and let the services create their
state directories, then stop Home Assistant and Matter Server before replacing
their data. Restore HA
configuration from `var/lib/hass/`, and the database from
`var/lib/home-assistant-backup/recorder/home-assistant_v2.db`. Remove stale
`home-assistant_v2.db-wal` and `home-assistant_v2.db-shm` before restoring the DB.
Ensure HA files belong to `hass:hass`.

Restore the staged `var/lib/home-assistant-backup/matterjs-server/` contents to
the existing Matter state directory. It uses systemd DynamicUser, so
`/var/lib/matterjs-server` can be a symlink into `/var/lib/private`; preserve the
host's directory layout and ownership rather than replacing that symlink or
blindly restoring an old numeric UID. Start the services and verify history and
paired devices. Do not run two controllers with a copied fabric concurrently.

### Later migration to R2

The reference uses `s3:https://ACCOUNT.r2.cloudflarestorage.com/restic-backup/HOST/SERVICE`.
When ready, create the bucket and scoped credentials, change the Restic
repository, and supply `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` through a
root-only `environmentFile` (prefer sops). Keep the repository password safe.
Use Restic's `copy` command with the local repository as the source if retaining
existing snapshots; merely changing the URL starts a separate repository.
Verify the R2 snapshots and a restore before removing local backups.

## Diagnostics and sources

```sh
systemctl status home-assistant matterjs-server victoriametrics
journalctl -u matterjs-server -u victoriametrics --since today
systemctl list-timers restic-backups-home-assistant.timer
journalctl -u restic-backups-home-assistant --since today
```

- [HA Matter](https://www.home-assistant.io/integrations/matter/)
- [Matter Server network requirements](https://github.com/matter-js/matterjs-server/blob/main/docs/os_requirements.md)
- [HA HTTP UI configuration](https://www.home-assistant.io/integrations/http/)
- [Recorder](https://www.home-assistant.io/integrations/recorder/)
- [Prometheus integration](https://www.home-assistant.io/integrations/prometheus/)
- [Reference Restic module](https://github.com/natsukium/dotfiles/blob/6cebb564ec31f4072db323b36a3b8455c9004322/modules/features/backup/restic/default.nix)
