# Monitoring

B450M-Pro4 runs single-node VictoriaMetrics, vmalert, Alertmanager, Grafana,
Loki and Tempo. VictoriaMetrics replaces the Prometheus **server**; Prometheus
exporters and the Prometheus query API remain in use. Configuration follows
[natsukium's monitoring modules](https://github.com/natsukium/dotfiles/tree/main/modules/features/monitoring),
with separate infrastructure and room alert routing and configurable environmental thresholds.

## Data flow

- Node exporters, Comin, Starla and Home Assistant → VictoriaMetrics.
- B450M SMART/NVMe health and NVIDIA GPU exporter → VictoriaMetrics.
- Claude Code and Codex → OTLP HTTP collector → VictoriaMetrics (metrics), Loki
  (logs), Tempo (traces).
- VictoriaMetrics → vmalert → Alertmanager → Discord infrastructure/room channels
  once notifications are configured.
- System service journals and Comin logs → Alloy → Loki.

Metrics retain one year, Loki logs 30 days and Tempo traces 30 days.
The [Codex reset history](codex-limit-auto-reset.md) stream retains 400 days
for its annual activity calendar; other Loki streams retain 30 days.
Loki stores its data on B450M's bulk filesystem at `/srv/bulk/loki` so the
crowded root filesystem does not trigger its WAL disk-usage protection.
The deployment migration preserves the old `/var/lib/loki` as a rollback copy;
stop Loki before copying data, and never merge two actively written databases.
The pre-existing Grafana datasource name **Prometheus** and UID are retained so
existing dashboards continue to work; it now queries VictoriaMetrics. The
**Home Assistant** datasource also points at this database. No Prometheus
server or separate HA metrics database is started.

Features live under `modules/features/observability/`. B450M enables
`my.services.monitoring`, `my.services.alertmanager`, `my.services.roomAlerts`
and `my.services.tempo`. Service-specific Comin rules remain beside Comin's
scrape configuration. B450M and UM790-Pro (the shared builder and agent server) default to
`always_on=true`; sleeping laptops and the desktop are not treated as outages. Change
`my.services.monitoring.alwaysOnHosts` when a host's operating schedule changes.
pi5 is not yet running NixOS and is excluded from both node-exporter and Comin
scrape targets. Add it only after the corresponding services are deployed.

## Hardware and clock warnings

Additional rules use the existing SMART and node exporters:

| Alert                              | Condition                                                                              | Duration  | Severity |
| ---------------------------------- | -------------------------------------------------------------------------------------- | --------- | -------- |
| `DiskBadSectors`                   | Raw SMART attribute 5, 197 or 198 is non-zero                                          | 15 min    | warning  |
| `DiskSmartAttributeBelowThreshold` | Normalized SMART value is at or below its non-zero vendor threshold                    | 30 min    | critical |
| `HostClockNotSynchronised`         | Unsynchronised status observed in the last 5 min and maximum clock error at least 16 s | 15 min    | warning  |
| `CpuTemperatureHigh`               | CPU temperature above 80°C or within 15°C of its critical threshold                    | 15 min    | warning  |
| `DiskIoBusy`                       | Five-minute disk busy time above 95%                                                   | 30 min    | warning  |
| `MemorySwapUsageHigh`              | Used swap above 80%, excluding hosts with no swap                                      | 15 min    | warning  |
| `MemoryEccCorrectableErrors`       | EDAC corrected-error counter increases within one hour                                 | 5 min     | warning  |
| `MemoryEccUncorrectableErrors`     | EDAC uncorrected-error counter increases within one hour                               | immediate | critical |

SMART comparisons match the same exporter, device and attribute. A vendor
threshold of zero is ignored. CPU warnings select `coretemp`, `k10temp`,
`zenpower` and `cpu_thermal` chip names, excluding GPU, NVMe and board sensors.
CPUs without an exported critical threshold still use the 80°C condition.
Clock and CPU rules cover reporting node exporters; missing metrics from a
sleeping client do not themselves trigger these rules.

Disk busy time excludes loop, RAM, floppy and device-mapper devices to avoid
virtual-device noise and counting both a mapped device and its backing disk.
A busy disk is not necessarily saturated, especially with parallel NVMe I/O.
High swap occupancy alone does not prove current memory pressure; correlate
it with available memory and swapping activity. EDAC alerts use counter
increases rather than lifetime totals and only cover hosts exposing those
counters. They report kernel observations, not a diagnosis of failed DIMMs;
inspect the affected host's kernel logs before deciding on hardware repair.

## Service availability

Uptime Kuma owns HTTP availability checks and their notifications. Its monitors
and status page are managed under `infra/uptime-kuma/`. Infrastructure Overview
links to its status page rather than duplicating HTTP checks in Blackbox.
VictoriaMetrics and vmalert handle host metrics, exporter availability, Comin
and room sensor thresholds. The retired Prometheus URL and ArchiveBox are not
monitored. Linkding, SearXNG, and Moe are included in HTTP monitoring and the
status page.

Deploy Kuma changes with the `Infra: Approved OpenTofu deploy` workflow on
`main`, selecting `target=uptime-kuma` and `mode=plan`. Review its plan, then
run `mode=apply` at the same main commit. If main has moved, review a new plan
first. The manual run only touches the selected infrastructure; the existing
PR approval labels still run all infrastructure roots.

## Grafana MCP

The shared Home Manager MCP module supports Grafana through
`mcp-servers-nix`, following [natsukium's configuration](https://github.com/natsukium/dotfiles/blob/main/modules/per-system/mcp-servers.nix).
It uses a dedicated Grafana service account token instead of the admin login.
Store the token as `grafana-mcp-token` in `secrets/grafana-mcp.yaml`, encrypted
with sops, then set this in the client Home Manager configuration:

```nix
my.programs.mcp.grafana.sopsFile = ../../../secrets/grafana-mcp.yaml;
```

The example path is relative to `homes/<platform>/<hostname>/default.nix`.
ThinkPad enables this integration with the encrypted token for the
`codex-mcp` Viewer service account. Other client hosts can opt in with the
same option if their Home Manager age key can decrypt the secret.
The MCP connects through `https://grafana.home.yutakobayashi.com`.
Use a Viewer service account for dashboard, metric and log queries. The MCP
wrapper reads the decrypted secret at startup through `passwordCommand` and
passes it as `GRAFANA_SERVICE_ACCOUNT_TOKEN`; the token is not embedded in
the Nix store or client configuration. Without a `sopsFile`, this integration
stays disabled. Apply the client configuration and restart the MCP client,
then verify dashboard discovery and a query against datasource
`PBFA97CFB590B2093` before considering the connection ready.

### ChatGPT through Secure Tunnel

B450M runs `tunnel-client-grafana`, which starts the Grafana MCP process on
the `main` channel over stdio with `--disable-write`. No new inbound MCP port
is opened. The Viewer token and OpenAI runtime key are supplied through
systemd `LoadCredential`; the health listener is `127.0.0.1:18794`.

Create the Grafana tunnel with OpenTofu in the separate
`tofu-configuration/infra/services/openai` repository. Put its output ID in
the root-only `/var/lib/grafana-mcp/mcp-tunnel.env` on B450M as
`CONTROL_PLANE_TUNNEL_ID=<tunnel ID>` (mode `0600`). The service stays skipped
until this file exists. Apply NixOS, start `tunnel-client-grafana`, and check
its journal and `/readyz` endpoint. The runtime API key needs Tunnels Read
and Use permissions for this tunnel; the organization admin key is only for
provisioning and must not be given to the daemon.

Associate the tunnel with the intended ChatGPT workspace in OpenAI Platform,
then add a custom MCP app in ChatGPT using **Connection → Tunnel** and
**Authentication → None**. Grafana authentication happens on B450M. Verify
tool discovery and a dashboard query from ChatGPT: local readiness alone
does not prove workspace association or end-to-end connectivity.

## Discord notifications

B450M enables Discord delivery using four sops-encrypted webhooks. Alertmanager
routes infrastructure and home alerts to the channels below.

Create one Discord webhook for each channel:

| Channel          | Routed alerts                                      | Repeat    | Recovery messages |
| ---------------- | -------------------------------------------------- | --------- | ----------------- |
| `infra-critical` | Infrastructure `critical`                          | 1 hour    | yes               |
| `infra-warning`  | Infrastructure `warning` and the default route     | 24 hours  | yes               |
| `infra-info`     | Infrastructure `info`                              | 120 hours | no                |
| `home`           | All `category=room` alerts, regardless of severity | 12 hours  | yes               |

Room events (`kind=event`) use the same `home` webhook, with a 10-second group
wait, a 120-hour repeat interval and no recovery message. This is four Discord
channels; the event route does not require a fifth webhook. Comin failure
alerts go to `infra-warning`; its full logs remain in Loki.

From the repository root, register the URLs with hidden terminal input:

```sh
nix shell --inputs-from . nixpkgs#sops --command python3 modules/features/observability/alertmanager/register-webhooks.py
```

The command encrypts the four URLs directly into `secrets/alertmanager.yaml`.
Plaintext stays in process memory and a pipe; it is not written to temporary
files, command arguments or the Nix store. The sops rule grants decryption to
B450M and the ThinkPad Home Manager age key. The command sends no Discord
messages. Re-run it to replace all four URLs when rotating webhooks.

B450M's system configuration enables the registered webhooks:

```nix
my.services.alertmanager.notifications = {
  enable = true;
  sopsFile = ../../../secrets/alertmanager.yaml;
};
```

Track the encrypted YAML with Git before Nix flake evaluation. sops-nix
provides root-only runtime secrets, and systemd passes them to Alertmanager
through `LoadCredential`. Secret changes restart Alertmanager. Revoke old
webhooks in Discord after deploying replacements. Do not paste URLs into
chat or put plaintext URLs in Git.

Grouping includes host and entity so different rooms are not conflated.
Critical alerts inhibit warnings of the same condition. Alertmanager HTTP
and gossip are not exposed to the LAN.

## Home Assistant sensors

The encrypted `home-assistant-mcp-authorization` sops secret is reused for
metrics. Its value contains the `Bearer ` prefix required by the MCP tunnel;
the metrics credential helper removes that prefix into a restricted runtime
file, without logging the value or putting it in the Nix store. See
[Home Assistant](home-assistant.md) for creation and rotation of the original
secret. A separate manually provisioned HA token is unnecessary.

The bedroom temperature and humidity entities were verified against the running
HA metrics endpoint and are configured in B450M. Add further real entity IDs to
`my.services.roomAlerts.sensors` in the B450M configuration.
Do not copy another installation's entity IDs. Confirm exported metric names,
units and entity labels through the authenticated `/api/prometheus` endpoint
or Grafana Explore. Example (replace the entity before enabling):

```nix
my.services.roomAlerts.sensors."sensor.actual_indoor_temperature" = {
  kind = "temperature";
  name = "Living room temperature";
};
```

The explicit allowlist prevents outdoor and equipment temperatures from firing
room alarms. Default temperature limits are 10–30 °C for 30 minutes, humidity
40–65% for one hour, CO₂ above 1500 ppm for 15 minutes and battery below 20% for
one hour. These are reference operating thresholds, not medical safety limits.
Adjust them per sensor. Metric names and thresholds can be overridden.

Missing sensor series are detected separately from HA scrape failures. A
constant exported value does not prove a physical sensor is still updating;
use a device-specific last-seen measurement when available. Sampled appliance
states cannot guarantee every short event is observed. Door/lock checks are
operational reminders, not a replacement for a security alarm.

## Claude Code and Codex

The managed CLI configurations enable OTLP exporters while disabling raw
prompt/content collection. The central collector also removes known sensitive
attributes from logs and traces. New SDK fields still need review; do not
assume this removes every possible secret in arbitrary telemetry.

The original Claude event dashboard is retained alongside metrics and Codex
views. Loki log trace IDs link to Tempo; traces link back to logs. Token usage
and exported errors/latencies come from client telemetry, not billing records.
Codex metrics are not interchangeable with Claude's cost metrics. Desktop apps
that do not inherit the managed CLI configuration must be verified separately.

Claude uses cumulative metrics and opt-in beta tracing. Codex configures
separate logs, metrics and traces exporters under `otel`. The Nix telemetry
endpoint option is the base URL (`http://B450M-Pro4.tail29d068.ts.net:4318`);
the generated Codex configuration appends `/v1/logs`, `/v1/metrics`, and
`/v1/traces` for the respective exporters.
The collector converts delta metrics to cumulative when necessary and pushes
remote write samples directly, so short sessions do not depend on a scrape.
Metric names use underscore escaping without additional unit/type suffixes.
Keep per-session identities on cumulative metrics to distinguish concurrent
clients; session/trace IDs should not become Loki index labels.
Codex 0.165.0's native metrics observed during verification do not include a
session identity. Short sessions can export only one sample, so `increase`
panels may show zero and `rate`-based latency panels may be empty despite
successful ingestion. These panels are not exact per-session accounting.

Apply the Home Manager configuration on each client host, including the
ThinkPad; deploying the collector on B450M does not update client settings.
The managed Codex wrapper also passes settings as command-line overrides, so
updating only `config.toml` is insufficient if the wrapper is still old.
Use a new CLI session after changing configuration. Confirm data arrives for
both clients rather than interpreting an empty panel as zero usage. An explicit
`analytics.enabled = false` in a Codex version that gates all metrics can stop
its metrics exporter; check the installed version and exporter diagnostics.

References: [Claude monitoring](https://code.claude.com/docs/en/monitoring-usage),
[Codex telemetry](https://learn.chatgpt.com/docs/config-file/config-advanced),
and [Codex exporter configuration](https://learn.chatgpt.com/docs/config-file/config-sample).

## Migration and verification

1. Preserve existing Prometheus storage before applying. This change does not
   delete `/var/lib/prometheus2` or automatically import its history. Use the
   pinned `vmctl` Prometheus import workflow against a snapshot if old metrics
   must appear in the unified database. Keep the original until query checks
   establish a successful import. Existing VictoriaMetrics storage is reused.
2. Build B450M and inspect the resulting config. `system.checks` validates
   vmalert expressions. Check Alertmanager config, collector config and the
   complete NixOS system evaluation as well.
3. Apply on B450M using the repository's normal deployment workflow. Verify
   `victoriametrics`, `vmalert-main`, `alertmanager`, `opentelemetry-collector`,
   `tempo` and `alloy` are active. Check journal errors and `/targets` on
   `http://127.0.0.1:8428` locally.
4. In Grafana, verify `up` for node, Comin, Starla and HA. Check service
   availability in Uptime Kuma. The Comin dashboard must still show
   deployments. Verify fresh Claude and Codex telemetry and a log→trace link.
5. Add the observed room entities, check that rules match real series, and
   verify that an intentionally absent test entity raises the missing-data
   rule. Avoid changing real room conditions just to test thresholds.
6. After configuring Discord, explicitly send a temporary test alert and its
   resolution to each channel. Configuration validation alone does not prove
   delivery. Remove the test alert afterward.

Grafana dashboards include Infrastructure Overview, Room Environment, Hardware
Overview, NVIDIA GPU, Comin, Claude Code and Codex. The NVIDIA view uses the
reference layout with GPU UUID filtering, utilization, VRAM, temperature/fan,
power/limit, throttling and clocks. Room Environment also compares the observed
HA air-conditioner temperature and set point. The metrics/rules APIs are local; use Grafana or an SSH
forward for inspection. The old `prometheus.home.yutakobayashi.com` route is
removed rather than exposing the new write-capable VictoriaMetrics API.

A monitoring stack on B450M cannot notify while B450M itself or the home uplink
is down. An independently hosted watchdog is a separate deployment. Metrics,
logs and traces also need a deliberate backup/capacity policy: the existing
HA Restic job does not back up these databases, and a one-year retention limit
is not a disk-size limit.
