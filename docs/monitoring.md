# Monitoring

B450M-Pro4 runs single-node VictoriaMetrics, vmalert, Alertmanager, Grafana,
Loki and Tempo. VictoriaMetrics replaces the Prometheus **server**; Prometheus
exporters and the Prometheus query API remain in use. Configuration follows
[natsukium's monitoring modules](https://github.com/natsukium/dotfiles/tree/main/modules/features/monitoring),
with infrastructure/room routing and environmental thresholds adapted from
[fa0311's monitoring](https://github.com/fa0311/home-server-compose/tree/main/monitoring).

## Data flow

- Node exporters, Comin, Starla, HTTP probes and Home Assistant → VictoriaMetrics.
- B450M SMART/NVMe health and NVIDIA GPU exporter → VictoriaMetrics.
- Claude Code and Codex → OTLP HTTP collector → VictoriaMetrics (metrics), Loki
  (logs), Tempo (traces).
- VictoriaMetrics → vmalert → Alertmanager → Discord infrastructure/room channels
  once notifications are configured.
- System service journals and Comin logs → Alloy → Loki.

Metrics retain one year, Loki logs 30 days and Tempo traces 30 days.
The pre-existing Grafana datasource name **Prometheus** and UID are retained so
existing dashboards continue to work; it now queries VictoriaMetrics. The
**Home Assistant** datasource also points at this database. No Prometheus
server or separate HA metrics database is started.

Features live under `modules/features/observability/`. B450M enables
`my.services.monitoring`, `my.services.alertmanager`, `my.services.roomAlerts`
and `my.services.tempo`. Service-specific Comin rules remain beside Comin's
scrape configuration. B450M, UM790-Pro (the shared builder and agent server), and pi5 default to
`always_on=true`; sleeping laptops and the desktop are not treated as outages. Change
`my.services.monitoring.alwaysOnHosts` when a host's operating schedule changes.

## Discord notifications

Delivery is deliberately disabled until webhooks are prepared. Alertmanager
still accepts alerts and Grafana can display their firing/pending state.

On B450M, create these final files with `sudoedit`, each containing only its
Discord webhook URL:

- `/var/lib/monitoring-secrets/discord-infrastructure`
- `/var/lib/monitoring-secrets/discord-room`

The directory must be root-owned mode 0700 and files mode 0600. Never put
webhook URLs in Git, shell arguments, chat, or temporary files. Set `my.services.alertmanager.notifications.enable = true` after provisioning.
Systemd loads the files as credentials. Rotate by editing the files and
restarting Alertmanager; revoke the old webhook in Discord.

Infrastructure critical alerts repeat hourly; warnings repeat daily. Room
alerts repeat every 12 hours. Event receivers suppress resolved messages.
Grouping includes host and entity so different rooms are not conflated.
Critical and warning levels of the same condition are inhibited together.
Alertmanager HTTP and gossip are not exposed to the LAN.

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
separate logs, metrics and traces exporters under `otel`; its endpoint option
is the base URL (`http://B450M-Pro4.tail29d068.ts.net:4318`), without `/v1/logs`.
The collector converts delta metrics to cumulative when necessary and pushes
remote write samples directly, so short sessions do not depend on a scrape.
Metric names use underscore escaping without additional unit/type suffixes.
Keep per-session identities on cumulative metrics to distinguish concurrent
clients; session/trace IDs should not become Loki index labels.

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
4. In Grafana, verify `up` for node, Comin, Starla, HA and probe jobs; verify
   `probe_success` for each local service. The Comin dashboard must still show
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
