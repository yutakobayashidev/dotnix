# Codex limit auto reset

UM790-Pro runs `codex-limit-auto-reset` as a Home Manager systemd user service
for `yuta`. The reusable module and package live in the personal project's flake;
dotnix imports `homeManagerModules.default` and enables it only in that
host's home configuration.

The shared NixOS user configuration enables linger, so the user manager starts
at boot and remains active after logout. The service belongs to `default.target`.
It uses the Home Manager Codex package and explicitly sets `CODEX_HOME` from
`home.sessionVariables.CODEX_HOME`, sharing the existing Codex authentication.
It does not depend on a login shell exporting variables.

After applying the configuration on UM790-Pro, check as `yuta`:

```bash
systemctl --user status codex-limit-auto-reset.service
journalctl --user -u codex-limit-auto-reset.service -n 50
loginctl show-user yuta -p Linger
```

The migration removes the former system service. After the first switch,
`systemctl is-active codex-limit-auto-reset.service` should report inactive,
while the user service should be active. Do not run both instances concurrently:
they use the same Codex account and redeem the same credits.

The earlier [system service design](superpowers/specs/2026-07-13-codex-limit-auto-reset-design.md)
is historical and is superseded by this user-service configuration.

## Low-usage resets

UM790-Pro sets `resetRemainingPercent = null`: low-remaining-quota redemption is
disabled, while the existing six-hour expiry trigger remains enabled. The code
and configurable threshold remain available for later use. With low-usage monitoring enabled, only one credit is selected per check, even
when both triggers apply. Expiry-only scheduling uses the upstream worker. Model-specific allowances
are excluded. The service does not resume tasks already stopped by a limit;
consumption between polls can still exhaust the allowance.

When low-usage monitoring is enabled, a pending redemption is saved at
`~/.local/state/codex-limit-auto-reset/recovery.json` before the request. Until
usage recovery is observed, the service may retry the same available credit
with the same idempotency key but will not select another. This guard survives
service restarts. Keep one worker per account; do not run another instance on
another host. If `usage_recovery_pending` persists, inspect account usage and
reset history before clearing the checkpoint. A corrupt checkpoint fails closed.

Set `resetRemainingPercent = null` to return to expiry-only scheduling.

## Reset history

The `codex-limit-auto-reset` flake input pins the [personal fork](https://github.com/yutakobayashidev/codex-limit-auto-reset).
Its daemon writes JSON lines with an ISO UTC `timestamp`, `level`, and `event`.
Redemption events also include `credit_id` and `attempt`; results include
`outcome`; the optional low-usage worker also includes `reason` (`expiry` or
`low_usage`). Each failed redemption attempt
is logged separately, and terminal initialization/check failures use `check_failed`.
Upstream failure events include safe error categories and may include a short
app-server error detail. Raw exceptions, stacks and RPC payloads are omitted.

Alloy on UM790-Pro reads `_SYSTEMD_USER_UNIT=codex-limit-auto-reset.service`,
keeps the recognized JSON events, and forwards them to Loki with
`job="codex-limit-auto-reset"`. Credit IDs stay in the JSON body, not index
labels. The original Codex subprocess stderr remains available in the local
journal, but is not included in this structured event stream.

Only `credit_redemption_result` with `outcome="reset"` counts as a confirmed
reset. `nothingToReset`, `noCredit`, and `alreadyRedeemed` are visible in history
but do not grow the calendar. Attempts and retries are not reset successes.
If the server succeeds but its response is lost, a subsequent `alreadyRedeemed`
cannot establish a confirmed reset; these logs are operational history, not a
transactional audit ledger.

History starts when the updated daemon and collector are applied. Old plain-text
logs are not automatically backfilled. An empty day before collection started,
or during a collection outage, does not prove zero resets.

## Grafana calendar

After applying UM790-Pro (daemon and Alloy) and B450M-Pro4 (Grafana and Loki),
open the reset history section in [Codex / Tibo](https://grafana.home.yutakobayashi.com/d/codex-usage-advisor).
The signed calendar panel displays one day per square in `Asia/Tokyo`; darker
green indicates fewer confirmed resets and brighter green indicates more.
The dashboard also shows totals, failed attempts/checks, recent check activity,
and the underlying result/error logs.

The calendar counts individual successful log records, rather than repeatedly
sampling a rolling 24-hour counter. This avoids overlapping windows and assigns
events to their actual Japanese calendar date. Rendering is capped at 5,000
success records per selected range; the total stat does not use this cap.
Empty cells mean no recorded reset, not proven uptime or successful collection.
The recent-check panel helps distinguish an idle daemon from missing telemetry.

Only this service's Loki stream retains 400 days, sufficient for the default
one-year view. Other streams keep their existing 30-day retention. Loki's query
length limit is raised to 400 days to permit the annual view; this does not
extend retention for other streams.

## Success notifications

Loki Ruler evaluates `CodexResetCompleted` every 30 seconds. It looks back
15 minutes for confirmed `reset` results and creates one alert identity per
host, user ID, and credit ID. The credit ID is extracted at query time, not
added to Loki's stored index labels.

Alertmanager routes this rule to the existing `infra-info` Discord webhook
with the title **Codex reset completed** and a link to the dashboard. Distinct
credits have distinct notification groups, even when reset in the same check.
The first notification waits 5 seconds; resolved notifications are disabled.
The repeat interval is 24 hours, longer than the 15-minute event window, so
normal operation sends no periodic reminder. Existing infrastructure alert
routes and repeat intervals are unchanged.

This is best-effort event notification, not exactly-once delivery. A prolonged
evaluation/delivery outage can miss an event, and an ambiguous delivery result
can cause a retry. The dashboard remains the place to inspect recorded history.
The Loki rule files are provisioned from the Nix store under the single-tenant
`fake` directory; its rule API remains disabled.
