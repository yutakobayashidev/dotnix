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

VictoriaMetrics stores both machine and Home Assistant metrics. Grafana retains
the **Home Assistant** data source alongside the existing **Prometheus** data
source name; both query VictoriaMetrics. See [monitoring](monitoring.md) for
alert rules and notification setup. Start with
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

## ChatGPT through Secure MCP Tunnel

Nix includes HA's `mcp_server` component and the
`tunnel-client-home-assistant` service on B450M-Pro4. The service forwards the
`main` channel to `http://127.0.0.1:8123/api/mcp` over an outbound OpenAI tunnel.
It does not require another router port or public HA endpoint. The health/admin
listener is loopback-only at `127.0.0.1:18793`.

After applying the Nix configuration:

1. In HA, add **Model Context Protocol Server** under Settings → Devices &
   services (or enable MCP under Settings → System → AI). Configure the
   integration to disable **Expose all LLM APIs** and select **Assist**, then
   expose only the entities ChatGPT should access. The default configuration
   requires an administrator account; either use an appropriate dedicated
   account or explicitly change that integration option for a non-admin user.
2. Create a long-lived access token for that HA account. Encrypt the complete
   value `Bearer <HA token>` as `home-assistant-mcp-authorization` in
   `systems/nixos/services/home-assistant/secrets.yaml` using sops. Only B450M-Pro4
   can decrypt this file. sops-nix provisions the root-only runtime secret and
   restarts the tunnel when it changes; systemd passes it via `LoadCredential`.
   The `Bearer ` prefix is required for MCP requests and probes.
3. Create the `openai_mcp_tunnel.home_assistant` resource in
   `tofu-configuration/infra/services/openai` after reviewing its plan. Read
   its ID with `tofu -chdir=infra/services/openai output -raw home_assistant_tunnel_id`
   from that repository. On B450M-Pro4 use `sudoedit` to create
   `/var/lib/home-assistant-secrets/mcp-tunnel.env` containing
   `CONTROL_PLANE_TUNNEL_ID=<the output ID>`.
4. Confirm the existing sops `openai-tunnel-api-key` is an OpenAI **runtime**
   key with Tunnels Read + Use access to this tunnel. The daemon must not use
   `OPENAI_ADMIN_KEY`. Then start it:

   ```sh
   sudo chmod 600 /var/lib/home-assistant-secrets/mcp-tunnel.env
   sudo systemctl start tunnel-client-home-assistant
   systemctl status tunnel-client-home-assistant
   curl --fail http://127.0.0.1:18793/readyz
   ```

5. In OpenAI Platform, associate the tunnel with the intended ChatGPT workspace.
   In ChatGPT, add a custom MCP server, select **Connection → Tunnel**, choose
   the new Home Assistant tunnel, and select **Authentication → None**. HA
   authentication is supplied by the local daemon; OAuth is not configured.
   Verify tools are listed, read one exposed entity, then test an intended
   device operation. The ChatGPT user also needs Tunnels Read + Use access.

The service is skipped until the sops secret and tunnel environment file exist.
The root-only environment folder survives reboots because `/var/lib` is persistent.
The encrypted HA token is tracked in Git; plaintext credentials are passed through
`LoadCredential` at runtime and never belong in Nix expressions, shell arguments,
or temporary files. To rotate the token, issue a replacement in HA, update the
sops value and deploy, then revoke the old token in HA.

For troubleshooting, use `journalctl -u tunnel-client-home-assistant --since today`.
A successful Nix evaluation verifies the configuration, not HA setup, runtime
key permissions, or the end-to-end ChatGPT connection.

## Enable metrics collection

Metrics reuse the encrypted `home-assistant-mcp-authorization` secret described
above. No separate plaintext token needs provisioning. A root oneshot reads the
secret through systemd credentials, verifies and removes the `Bearer ` prefix,
and writes `/run/home-assistant-metrics/token` (mode 0640, dedicated group).
VictoriaMetrics reads that runtime token through a supplementary group.
Secret rotation restarts the helper and VictoriaMetrics as well as the MCP tunnel.

Do not put tokens in Nix expressions, shell command arguments, Git, or `/tmp`.
A failed token helper does not stop infrastructure metrics: the HA scrape and
its availability alert report the missing data. The metrics API binds only to
`127.0.0.1:8428`; HA's metrics endpoint still requires authentication.

Check `http://127.0.0.1:8428/targets` on the server, or query
`up{job="home-assistant"}` through Grafana; it must become 1. The filter exports
sensors, binary sensors, climates, lights, switches and locks. Narrow it to observed
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

- [HA MCP Server](https://www.home-assistant.io/integrations/mcp_server/)
- [Secure tunnel configuration](https://github.com/openai/tunnel-client/blob/main/docs/configuration.md)
