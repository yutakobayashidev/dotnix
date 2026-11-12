# Coding agent monitoring

The [Coding Agents dashboard](https://grafana.home.yutakobayashi.com/d/coding-agents)
combines Claude Code, Codex and Pi usage, latency, errors, events and traces.
It adapts the CC0-licensed [natsukium/dotfiles implementation](https://github.com/natsukium/dotfiles/tree/1a73d4fdf47f0dc28509cb304f44646f1edf56a4/modules/features/monitoring)
and its Pi telemetry extension at the same revision.

## Collection

Managed NixOS and macOS hosts with an enabled agent use Alloy on
`127.0.0.1:4318`. It adds the host identity, removes known sensitive log/span
attributes and forwards OTLP HTTP over Tailscale to B450M-Pro4:4318.
B450M uses the same Alloy service for journals and agent ingestion, replacing
the standalone OpenTelemetry collector. It converts delta metrics to cumulative
and pushes samples to VictoriaMetrics, sends logs to Loki and traces to Tempo.
The existing central endpoint remains available to Ori and older clients.
Standalone Home Manager clients retain that endpoint as their default.

Unlike the reference implementation, forwarding clients do not write directly
to storage backends. Storage APIs stay local to B450M. Only the receiver is
reachable over the existing trusted tailnet; client receivers are loopback-only.
`my.services.agentTelemetry` controls enablement, forwarding endpoint and server
mode. The unified `my.services.alloy` interface supports Linux and macOS.
Full Linux Alloy configuration is validated during the system build.

Pi installs `~/.pi/agent/extensions/otel-metrics.ts`. It exports token usage,
estimated cost, new sessions and tool successes/failures, without message or
tool contents. A zero baseline before the first delta preserves short-session
increases. Each process has a separate service instance identity. Resuming a
session does not increment the new-session counter. Export failures do not
interrupt Pi; its in-memory buffer is not a durable usage ledger.

## Privacy and interpretation

Existing Claude/Codex prompt and tool-content collection defaults remain off.
Both collection stages remove the known sensitive attributes listed in
`agent-telemetry.nix`; this is not a general content sanitizer. Session and trace
identifiers are retained for diagnostics, but are not Loki index labels.
Codex per-turn and conversation metric labels are removed to limit cardinality.
Native Codex metrics without a session identity can undercount concurrent or
single-sample sessions. Cost values are telemetry estimates, not invoices.
Missing data is shown as missing rather than forced to zero.

The local forwarding queue is memory-only and retries while Alloy is running;
restarts or long outages can lose queued telemetry. Central delta accumulation
also resets on collector restart. Historical metrics and logs remain in the
existing databases. Historical series without `host` do not match a selected
host. The original Claude event detail view remains available; the two redundant
Claude metrics/Codex views are removed through Grafana provisioning.

## Rollout and verification

1. Build and deploy B450M through Comin. Confirm Alloy, VictoriaMetrics, Loki
   and Tempo are active and the old collector is stopped. Port 4318 must have
   only the Alloy listener; Tempo keeps its existing loopback 4317 listener.
2. Apply the client system and Home Manager configuration together, then start
   new agent sessions. Existing Codex wrappers retain their old overrides until
   updated. A server deployment alone does not switch clients to local Alloy.
3. Check `journalctl -u alloy` on Linux, or `/var/log/alloy/alloy.err.log` on
   macOS. In Grafana, verify fresh series with the expected `host`, a log and a
   trace, as supported by each client. Pi emits metrics only.
4. Exercise a short Pi session and inspect its token/session increase. Run
   `node --test tests/pi-otel-metrics.mjs` (Node 24+) for extension regression
   checks. Do not interpret an empty agent panel as proof of zero usage.

See [monitoring](monitoring.md) for storage retention, alerting and access.
