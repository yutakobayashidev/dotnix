# Codex account advice

UM790-Pro runs the personal fork's `codex-usage-advisor` every five minutes through
a Home Manager user timer. It reads **all** locally registered codex-auth accounts
and the unofficial nextreset.ai forecast, then emits suggestions only. It never
switches accounts or consumes reset credits. Low-quota auto redemption is disabled;
the existing expiry-only reset worker remains enabled.

The advisor is configured under `services.codex-limit-auto-reset.advisor` in the
UM790-Pro home configuration. The package and reusable module come directly from
the personal fork's pinned flake input, rather than the older NUR package.

## Inputs and estimates

- Each account's short/weekly windows, reset times, and available credit expiries
  come from `codex-auth list --api --json`. Cached or failed refreshes are excluded.
- The advisor records up to six hours of percentage observations per account/window.
  It requires at least four samples over 15 minutes. Only intervals where the account
  was selected at both ends count; this is not a measurement of actual working time.
- Consumption is `(percentage-point increase + 1 rounding-margin point) / hours`.
  Remaining hours are `remaining percentage / consumption`. Resets and long gaps
  break observations. No consumption or insufficient history means unknown.
- No percentage rate is transferred between accounts/plans. Candidate ordering by
  remaining percentage is a coarse headroom heuristic, not token capacity equivalence.
- Tibo forecasts retain their published horizons. A 24-hour probability cannot justify
  waiting with a one-hour runway. Expired, degraded or failed forecasts fall back to
  measured usage and scheduled recovery. Predictions are uncalibrated, not guarantees.

Default alerts: minimum remaining <=20%, estimated runway <=2 hours, or a reset
credit expiring within 6 hours. The probability threshold is 0.7. All are configurable.
Expiry advice precedes switching advice when the current account has an expiring
credit; verify whether the separate expiry worker has actually recovered the quota.

## Delivery

The advisor emits structured `usage_advice` events. UM790-Pro's existing Alloy forwards
the journal to Loki. The `CodexAccountAdvice` rule on B450M-Pro4 routes through the
existing Alertmanager `infra-info` Discord receiver. There is no new webhook secret.

Account numbers refer to the snapshot at notification time; consult `codex-auth list`
before manually switching. Emails, raw account IDs, credentials and raw API errors
are not emitted. The state file contains hashed keys, quota samples and notification
deduplication state only.

Identical recommendations repeat no sooner than six hours, with at least 30 minutes
between changed recommendations. This is best-effort: stdout emission is recorded,
not Discord acknowledgement. A pipeline outage can delay a recommendation until its
next eligible emission. The Loki event window is 15 minutes and resolved alerts are
not sent to Discord.

## Operations

```bash
systemctl --user status codex-usage-advisor.timer
journalctl --user -u codex-usage-advisor.service -n 30
systemctl --user start codex-usage-advisor.service
```

The packaged `codex-usage-advisor --dry-run` reads live state and previews a recommendation
without updating advisor history or emitting a notification event. codex-auth still
refreshes its own usage cache. Failures log `advisor_failed`; successful non-notifying
checks log `advisor_checked`. A kernel lock serializes normal invocations.

The advisor cannot migrate existing sessions or resume stopped tasks. Its `active`
account is codex-auth's selected account, not an inventory of all running Codex processes.

Low-usage redemption was disabled immediately with the user-unit drop-in
`~/.config/systemd/user/codex-limit-auto-reset.service.d/90-disable-low-usage.conf`
(`UnsetEnvironment=RESET_REMAINING_PERCENT`). The declarative setting is also null.
Remove that drop-in only if intentionally re-enabling low-quota resets later.

To register an additional account, use codex-auth login/import on UM790-Pro. Credentials
belong in its persistent CODEX_HOME with restrictive permissions, never in this repo
or /tmp. During setup the second existing account was transferred over SSH, imported
from a mode-0600 file in persistent user state, and the staging copy was removed after
success. The existing active auth file was verified unchanged.

Sources: [personal fork](https://github.com/yutakobayashidev/codex-limit-auto-reset/tree/main),
[forecast methodology](https://nextreset.ai/forecast/).

## Initial rollout (2026-11-18)

The changes were applied selectively, without switching unrelated worktree changes:

- UM790-Pro: the advisor's user unit/timer were installed from the evaluated settings;
  the package is GC-rooted at `~/.local/state/codex-usage-advisor/package`. The existing
  `/etc/alloy/codex-limit-auto-reset.alloy` includes the advisor collector.
- B450M-Pro4: existing Loki rules were copied intact to
  `/var/lib/loki/codex-advisor-rules`, with `fake/advisor.yaml` added. The validated config
  `/var/lib/loki/codex-advisor-config.json` changes only the rules directory. The persistent
  `/etc/systemd/system.control/loki.service.d/90-codex-advice.conf` selects it.
- The existing Alertmanager info route already delivers to `infra-info`; the declarative
  dedicated route additionally groups advice by ID. No webhook credential was copied.

These targeted settings survive reboot. When applying the full Nix configuration, first
remove the manually installed advisor service/timer files from `~/.config/systemd/user`
if Home Manager reports a collision (preserve the state directory). After the new Loki
unit/config is deployed, remove the above `system.control` drop-in, run daemon-reload,
and restart Loki so the declarative rules path takes over. Then the copied Loki config/
rules and the advisor's standalone GC root can be removed. Do not remove the state JSON
to force notifications: it contains consumption history and deduplication state.

Validation: the package builds, 55 tests pass, and the production dry run reads both
accounts. A clearly labeled one-time delivery test traversed the user journal, Alloy,
Loki and Alertmanager's infra-info route. The Discord notification counter advanced
from 46 to 47 with all Discord failure counters at zero. The temporary test hook was removed.

## Grafana / Tibo monitor integration

[Codex / Tibo dashboard](https://grafana.home.yutakobayashi.com/d/codex-usage-advisor)
combines account freshness/selection, quota history, measured consumption speed,
runway, scheduled recovery, credit count/expiry, Tibo forecast horizons, advice,
and the existing Tibo monitor's announcement-delivery logs. Its source is
`modules/features/observability/codex-reset-dashboard/dashboards/codex-usage-advisor.json`.

The Tibo monitor remains an independent public announcement poller. Its journal
is collected as `job="tibo-reset-monitor"`; Discord delivery/deduplication is
unchanged. Dashboard annotations mark notification time, not the actual time
all accounts recovered. A banked credit announcement is not a quota reset.
No past notifications are resent. Forecasts come from nextreset.ai, while
announcements come from codex-resets.com.

Current numeric values expire after 15 minutes. Invalid/stale account observations
hide quota series, and invalid forecasts hide probability series. Unknown rates,
runway and credit expiry are explicitly cleared (internal `-1`, filtered after
`last_over_time`), never shown as zero or retained indefinitely from an earlier poll.
The selected account reflects codex-auth on UM790; existing clients on other
machines may have different credentials. Rate estimation needs four observations,
at least 15 minutes, and positive usage while that account is selected.

### Temporary runtime provisioning (2026-11-18)

To avoid applying unrelated pending Nix edits, the dashboard was deployed using
Grafana's file provisioning. B450M-Pro4 uses a copy of its existing providers in
`/var/lib/grafana/advisor-provisioning`, with the additional dashboard in
`/var/lib/grafana/codex-advisor-dashboards`. The override is
`/etc/systemd/system.control/grafana.service.d/90-codex-advisor.conf`.
After a full Nix deployment installs the dashboard through the existing
`codex-reset` provider, remove this override, daemon-reload and restart Grafana,
then remove those two temporary persistent directories. Do not remove the existing
Grafana data directory. The Tibo Alloy fragment already uses its final
`/etc/alloy/tibo-reset-monitor.alloy` destination.

The reset worker's updated package is selected by the temporary UM790 user drop-in
`codex-limit-auto-reset.service.d/80-upstream-package.conf`. Remove that drop-in
after Home Manager installs the pinned package. The separate
`90-disable-low-usage.conf` continues disabling low-quota resets.

`codex-auth` does not advance `updated_at` when API values are unchanged. The
adapter therefore timestamps a newly confirmed API observation itself, requiring
`refresh.requested=true`, `method=api`, `status=ok`, and `source=api`. Unchanged
samples count toward the consumption timeline; a failed or skipped refresh does
not acquire a new timestamp.

The unified dashboard also includes reset-credit redemption totals, the Japan-time
annual calendar, results and worker failures. The calendar defaults to the last
year when the dashboard uses a relative time range; other history panels follow
the selected range. The old `codex-reset-history` dashboard is retired.

The runtime provisioning copy now points `nix-managed` at
`/var/lib/grafana/managed-dashboards` (without the retired Claude telemetry
screen) and `codex-reset` at the empty `/var/lib/grafana/retired-codex-dashboards`
with deletion enabled. These two directories can also be removed after the
Grafana provisioning override is retired following a full Nix deployment.
