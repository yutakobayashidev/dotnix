#!/usr/bin/env python3
import argparse
import datetime as dt
import json
import os
import sys
import urllib.parse
import urllib.request
from zoneinfo import ZoneInfo

BASE = "https://api.ouraring.com/v2/usercollection"


def _http_get(path: str, token: str):
    req = urllib.request.Request(
        path,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read().decode("utf-8"))


def _fetch_daily(kind: str, start_date: str, end_date: str, token: str):
    q = urllib.parse.urlencode({"start_date": start_date, "end_date": end_date})
    url = f"{BASE}/{kind}?{q}"
    data = _http_get(url, token)
    return data.get("data", [])


def _avg(vals):
    vals = [v for v in vals if isinstance(v, (int, float))]
    if not vals:
        return None
    return sum(vals) / len(vals)


def _pick(entry, *keys):
    cur = entry
    for k in keys:
        if not isinstance(cur, dict) or k not in cur:
            return None
        cur = cur[k]
    return cur


def _to_hours(seconds):
    if not isinstance(seconds, (int, float)):
        return None
    return round(seconds / 3600.0, 2)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--date", default="today", help="today or YYYY-MM-DD")
    ap.add_argument("--tz", default="Asia/Tokyo")
    args = ap.parse_args()

    token = os.getenv("OURA_PERSONAL_ACCESS_TOKEN")
    if not token:
        print(json.dumps({"ok": False, "error": "OURA_PERSONAL_ACCESS_TOKEN is not set"}, ensure_ascii=False))
        sys.exit(1)

    tz = ZoneInfo(args.tz)
    if args.date == "today":
        target = dt.datetime.now(tz).date()
    else:
        target = dt.date.fromisoformat(args.date)

    baseline_days = 7
    start = target - dt.timedelta(days=baseline_days)

    start_s = start.isoformat()
    end_s = target.isoformat()

    try:
        sleeps = _fetch_daily("daily_sleep", start_s, end_s, token)
        readiness = _fetch_daily("daily_readiness", start_s, end_s, token)
        activity = _fetch_daily("daily_activity", start_s, end_s, token)
    except Exception as e:
        print(json.dumps({"ok": False, "error": f"fetch failed: {e}"}, ensure_ascii=False))
        sys.exit(2)

    by_day = {
        "sleep": {d.get("day"): d for d in sleeps if d.get("day")},
        "readiness": {d.get("day"): d for d in readiness if d.get("day")},
        "activity": {d.get("day"): d for d in activity if d.get("day")},
    }

    day = target.isoformat()
    today_sleep = by_day["sleep"].get(day, {})
    today_readiness = by_day["readiness"].get(day, {})
    today_activity = by_day["activity"].get(day, {})

    # common fields (best effort across evolving schemas)
    sleep_score = _pick(today_sleep, "score")
    readiness_score = _pick(today_readiness, "score")
    activity_score = _pick(today_activity, "score")

    total_sleep_sec = _pick(today_sleep, "total_sleep_duration")
    if total_sleep_sec is None:
        total_sleep_sec = _pick(today_sleep, "contributors", "total_sleep", "value")

    rhr = _pick(today_readiness, "contributors", "resting_heart_rate", "value")
    hrv = _pick(today_readiness, "contributors", "hrv_balance", "value")

    prev_days = [(target - dt.timedelta(days=i)).isoformat() for i in range(1, baseline_days + 1)]

    b_sleep = _avg([_pick(by_day["sleep"].get(d, {}), "score") for d in prev_days])
    b_readiness = _avg([_pick(by_day["readiness"].get(d, {}), "score") for d in prev_days])
    b_activity = _avg([_pick(by_day["activity"].get(d, {}), "score") for d in prev_days])
    b_rhr = _avg([_pick(by_day["readiness"].get(d, {}), "contributors", "resting_heart_rate", "value") for d in prev_days])

    flags = []
    if isinstance(readiness_score, (int, float)) and isinstance(b_readiness, (int, float)) and readiness_score <= b_readiness - 10:
        flags.append("READINESS_DROP")
    if isinstance(sleep_score, (int, float)) and isinstance(b_sleep, (int, float)) and sleep_score <= b_sleep - 10:
        flags.append("SLEEP_SCORE_DROP")
    if isinstance(total_sleep_sec, (int, float)) and total_sleep_sec < 6 * 3600:
        flags.append("SHORT_SLEEP")
    if isinstance(rhr, (int, float)) and isinstance(b_rhr, (int, float)) and rhr >= b_rhr + 5:
        flags.append("RHR_SPIKE")

    out = {
        "ok": True,
        "day": day,
        "today": {
            "readiness_score": readiness_score,
            "sleep_score": sleep_score,
            "activity_score": activity_score,
            "sleep_hours": _to_hours(total_sleep_sec),
            "resting_heart_rate": rhr,
            "hrv_balance": hrv,
        },
        "baseline": {
            "readiness_score_7d": round(b_readiness, 2) if isinstance(b_readiness, (int, float)) else None,
            "sleep_score_7d": round(b_sleep, 2) if isinstance(b_sleep, (int, float)) else None,
            "activity_score_7d": round(b_activity, 2) if isinstance(b_activity, (int, float)) else None,
            "resting_heart_rate_7d": round(b_rhr, 2) if isinstance(b_rhr, (int, float)) else None,
        },
        "flags": flags,
    }

    print(json.dumps(out, ensure_ascii=False))


if __name__ == "__main__":
    main()
