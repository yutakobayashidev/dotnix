---
name: oura-daily-watch
description: Build and run a daily Oura + Discord behavior monitor. Use when the user wants morning wellness summaries, anomaly alerts, readiness/sleep trend checks, or advice based on Oura Ring data combined with chat activity patterns.
metadata: {"openclaw":{"requires":{"bins":["python3"],"env":["OURA_PERSONAL_ACCESS_TOKEN"],"config":[]},"primaryEnv":"OURA_PERSONAL_ACCESS_TOKEN"}}
user-invocable: true
---

# oura-daily-watch

Generate daily Oura summaries and anomaly hints, optionally combined with Discord activity patterns.

## Prereqs

- `python3`
- Env var:
  - `OURA_PERSONAL_ACCESS_TOKEN`

## Fetch Oura metrics

Run:

```bash
python3 {baseDir}/scripts/oura_fetch.py --date today --tz Asia/Tokyo
```

For a specific day:

```bash
python3 {baseDir}/scripts/oura_fetch.py --date 2026-02-12 --tz Asia/Tokyo
```

The script returns JSON with:

- `today`: daily metrics snapshot (sleep/readiness/activity)
- `baseline`: 7-day baseline averages (where available)
- `flags`: anomaly flags (readiness drop, short sleep, RHR spike, etc.)

## Combine with Discord behavior (optional but recommended)

When user wants mood/activation context, read channel messages and compute lightweight behavior signals:

- message count in last 24h
- late-night activity ratio (e.g. 00:00–05:00 JST)
- sudden spike vs recent average (best effort)

Use `message.read` for channel history, then summarize only aggregate stats (no sensitive content dump).

## Output pattern

For morning post (short):

- Readiness / Sleep / Activity scores
- Sleep duration and any notable deviation from baseline
- 1-line behavior note from Discord activity (if collected)
- Advice:
  - normal day: short maintenance tip
  - anomaly day: concrete low-friction actions (rest, hydration, meeting load, nighttime cutoff)

## Alerting policy

- Always include morning summary (daily)
- Add stronger advisory language when `flags` is non-empty
- If Oura fetch fails: output `Oura未取得` + reason, and do not hallucinate values

## Integration pattern: weather + Oura daily post

When the user wants Oura to appear in a daily weather post:

1. Keep weather as the first block.
2. Run `oura_fetch.py` and append a short Oura block.
3. If `flags` is empty: add 1-line maintenance advice.
4. If `flags` is non-empty: add concrete low-friction anomaly advice.
5. Keep total output concise (typically 8–14 lines).

Recommended heading:

- `【毎朝の天気+Oura】藤沢市・渋谷区`

## Safety

- Treat this as health-supporting insight, not medical diagnosis
- Avoid definitive medical claims
- Keep recommendations practical and reversible
