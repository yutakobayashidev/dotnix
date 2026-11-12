# Coding agent monitoring

The [Coding Agents dashboard](https://grafana.home.yutakobayashi.com/d/coding-agents)
combines Claude Code, Codex, Pi and dsh usage, latency, errors, events and traces.
It uses the local-collector pattern and Pi extension from the CC0-licensed
[upstream implementation](https://github.com/natsukium/dotfiles/tree/840060e3c97823608781697a6b3d2fd8a0789dfe/modules/features/monitoring).
The dsh instrumentation and legacy ingress are local additions. Prompt/content
capture stays disabled, unlike the upstream personal tracing configuration.

## Collection

Managed NixOS and macOS hosts use a loopback Alloy receiver. Claude Code and
Codex send OTLP/gRPC to `127.0.0.1:4317`; Pi and dsh use OTLP/HTTP on port
4318 (4319 on B450M, where 4318 remains the legacy remote ingress).
Each host adds its own identity, removes known sensitive log/span attributes,
converts delta metrics to cumulative with a 168-hour stale timeout, and writes
directly to VictoriaMetrics over Tailscale. Logs go to Loki and traces to Tempo.
Per-host accumulation and remote-write host labels follow the local collector
pipeline; one central accumulator no longer handles every active client.

B450M accepts remote-write on 8428, Loki OTLP on 3100, and Tempo OTLP/gRPC on 14317. Its firewall permits these ports through the already trusted Tailscale
interface, not through the ordinary network interfaces. Tempo uses 14317 so it
does not conflict with the local Alloy gRPC receiver on 4317.

A separate legacy HTTP pipeline on B450M:4318 continues to accept Ori and older
sessions. It preserves their supplied identity and uses `unknown` when none is
present; it never assigns B450M's identity to anonymous remote telemetry.
Restart managed agents after activation to move them to the local receiver.
Standalone Home Manager clients retain the legacy HTTP endpoint as their default.
`my.services.agentTelemetry` controls enablement, storage host, local HTTP port
and server mode. The shared Alloy interface supports Linux and macOS.
Full Linux Alloy configuration is validated during the system build.

The UM790 workspace runtime uses loopback port 4320, leaving 4318 for OTLP.

Pi installs `~/.pi/agent/extensions/otel-metrics.ts`. It exports token usage,
estimated cost, new sessions and tool successes/failures, without message or
tool contents. A zero baseline before the first delta preserves short-session
increases. Each process has a separate service instance identity. Resuming a
session does not increment the new-session counter. Export failures do not
interrupt Pi; its in-memory buffer is not a durable usage ledger.

dsh uses a declarative `--patch` plugin in both its managed CLI and Web service.
`my.programs.dsh.telemetry.enable` disables it; `telemetry.endpoint` selects the
OTLP HTTP metrics receiver. The plugin wraps the `llm/stream` extension point
in dsh 0.2.2-rc.1 and exports cumulative token counters, request outcomes and
summed request duration. The latest provider usage sample wins within each
call; retries count as separate calls. Input, output, cache reads and cache
writes are disjoint. Reasoning tokens are not added again to output.

Collection starts with new calls after the managed process is restarted; it
does not replay saved conversations or backfill historical usage. Helper calls
such as session titles and compaction are included. The usage coverage panel
shows how many calls reported token usage; failed requests may omit it. No
cost is inferred for subscription providers. No prompts, responses, tool
arguments, errors, session IDs or credentials are exported. This does not
enable dsh's separate session-history/feedback telemetry exporter.

Cumulative samples are sent every 10 seconds and on clean disposal. A
collector outage does not interrupt a call; a later sample can recover counts
while that process stays alive. An abrupt exit can lose the last window.
An initial zero is sent for each series; if that baseline is lost, the first
increase can be missed. Process IDs are random telemetry identities so
concurrent CLI/Web processes do not overwrite one another.

## Privacy and interpretation

Existing Claude/Codex prompt and tool-content collection defaults remain off.
The local and legacy pipelines remove the known sensitive attributes listed in
`agent-telemetry.nix`; this is not a general content sanitizer. Session and trace
identifiers are retained for diagnostics, but are not Loki index labels.
Codex per-turn and conversation metric labels are removed to limit cardinality.
Native Codex metrics without a session identity can undercount concurrent or
single-sample sessions. Cost values are telemetry estimates, not invoices. A Codex cost counter is
emitted only when the client receives an estimated turn cost; token telemetry
does not imply that this field is available. No absent cost is synthesized as zero.
Missing data is shown as missing rather than forced to zero.

Delta accumulation is in memory and resets on each collector restart.
Prometheus remote-write uses Alloy's WAL; it does not make in-flight agent
exports or the delta accumulator durable. Historical metrics and logs remain in the
existing databases. Historical series without `host` do not match a selected
host. The original Claude event detail view remains available; the two redundant
Claude metrics/Codex views are removed through Grafana provisioning.

## Rollout and verification

1. Build and deploy B450M through Comin. Confirm Alloy, VictoriaMetrics, Loki
   and Tempo are active and the old collector is stopped. Port 4318 must have
   only the legacy Alloy listener; local gRPC uses 4317 and Tempo uses 14317.
2. Apply the client system and Home Manager configuration together, then start
   new agent sessions. Existing Codex wrappers retain their old overrides until
   updated. A server deployment alone does not switch clients to local Alloy.
3. Check `journalctl -u alloy` on Linux, or `/var/log/alloy/alloy.err.log` on
   macOS. In Grafana, verify fresh series with the expected `host`, a log and a
   trace, as supported by each client. Pi emits metrics only.
4. Exercise a short Pi session and inspect its token/session increase. Run
   `node --test tests/pi-otel-metrics.mjs` (Node 24+) for extension regression
   checks. Do not interpret an empty agent panel as proof of zero usage.

The collector integration test runs generated server configuration against
isolated Alloy and VictoriaMetrics processes, without writing to production:

```sh
python3 tests/agent-telemetry.py --alloy /path/to/alloy \
  --victoriametrics /path/to/victoria-metrics --config /path/to/server.alloy
```

It checks local identity, cost aggregation across turn IDs, concurrent Pi
streams, and legacy identity fallback. Use `nix eval --raw
.#nixosConfigurations.B450M-Pro4.config.my.services.alloy.configs.agent-telemetry`
to obtain the configuration.

See [monitoring](monitoring.md) for storage retention, alerting and access.
