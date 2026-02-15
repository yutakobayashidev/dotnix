/* Core helpers for social-digest.
   Keep this file side-effect free so it can be unit-tested.
*/

export type Args = {
  date: string; // today or YYYY-MM-DD
  discordChannel?: string;
  mastodonAcct?: string;
  out: string;
  format: "daily";
};

const KEY_ALIASES: Record<string, string> = {
  "discord-channel": "discordChannel",
  "mastodon-acct": "mastodonAcct",
};

export function parseArgs(argv: string[]): Args {
  const args: any = { out: "Daily/Social", format: "daily" };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith("--")) continue;
    const rawKey = a.slice(2);
    const key = KEY_ALIASES[rawKey] ?? rawKey;
    const val = argv[i + 1];
    if (val && !val.startsWith("--")) {
      args[key] = val;
      i++;
    } else {
      args[key] = true;
    }
  }
  if (!args.date) throw new Error("--date is required (today or YYYY-MM-DD)");
  if (!args.out) args.out = "Daily/Social";
  if (!args.format) args.format = "daily";
  return args as Args;
}

export function jstDateRange(dateArg: string, now = new Date()): { ymd: string; start: Date; end: Date } {
  // Interpret date in Asia/Tokyo.
  const offset = "+09:00";
  const ymd =
    dateArg === "today"
      ? now.toLocaleDateString("en-CA", { timeZone: "Asia/Tokyo" })
      : dateArg;

  if (!/^\d{4}-\d{2}-\d{2}$/.test(ymd)) throw new Error(`Invalid date: ${dateArg}`);

  const start = new Date(`${ymd}T00:00:00${offset}`);
  const end = new Date(`${ymd}T24:00:00${offset}`);
  return { ymd, start, end };
}

export function stripHtml(html: string): string {
  return html
    .replace(/<br\s*\/>/gi, "\n")
    .replace(/<\/?p>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

export function parseMastodonAcct(acct: string): { username: string; host: string; baseUrl: string } {
  const [username, host] = acct.split("@");
  if (!username || !host) throw new Error(`Invalid mastodon acct: ${acct}`);
  return { username, host, baseUrl: `https://${host}` };
}

const TRACKING_PARAMS = new Set([
  "utm_source",
  "utm_medium",
  "utm_campaign",
  "utm_term",
  "utm_content",
  "utm_id",
  "utm_name",
  "utm_reader",
  "utm_referrer",
  "utm_social",
  "utm_social-type",
  "utm_brand",
  "utm_cid",
  "utm_pid",
  "utm_sid",
  "utm_ref",
  "fbclid",
  "gclid",
  "gbraid",
  "wbraid",
  "msclkid",
]);

export function normalizeUrl(raw: string): string {
  try {
    const u = new URL(raw);
    // Drop tracking params.
    for (const k of [...u.searchParams.keys()]) {
      if (TRACKING_PARAMS.has(k.toLowerCase())) u.searchParams.delete(k);
    }
    // Drop empty query.
    const q = u.searchParams.toString();
    u.search = q ? `?${q}` : "";
    // Keep hash (some sites use it), but you can remove if you prefer.
    return u.toString();
  } catch {
    return raw;
  }
}

export function rewriteUrlForFetch(raw: string): string {
  // Keep the display URL unchanged, but rewrite some hosts to a fetch-friendly URL.
  // This is meant for web_fetch only.
  try {
    const u = new URL(raw);
    const host = u.hostname.replace(/^www\./, "");

    // X/Twitter -> FixTweet API (more stable than embed scraping for text extraction)
    if (host === "x.com" || host === "twitter.com" || host === "mobile.twitter.com") {
      const idMatch = u.pathname.match(/\/status\/(\d+)/);
      if (idMatch) {
        const tweetId = idMatch[1];
        // screen_name is optional/ignored by FixTweet API, but passing one improves readability.
        const parts = u.pathname.split("/").filter(Boolean);
        const screen = parts[0] && parts[0] !== "i" ? parts[0] : "status";
        return `https://api.fxtwitter.com/${screen}/status/${tweetId}/ja`;
      }
    }

    return raw;
  } catch {
    return raw;
  }
}

export function extractUrls(text: string): string[] {
  // Conservative URL extractor. We intentionally avoid parsing markdown deeply.
  // Captures http(s) links and trims common trailing punctuation.
  const re = /https?:\/\/[^\s<>"')\]]+/g;
  const hits = text.match(re) ?? [];
  const cleaned = hits
    .map((u) => u.replace(/[\.,;:!\?\)\]\}]+$/g, ""))
    .filter(Boolean)
    .map(normalizeUrl);
  // Dedupe while keeping order.
  const seen = new Set<string>();
  const out: string[] = [];
  for (const u of cleaned) {
    if (seen.has(u)) continue;
    seen.add(u);
    out.push(u);
  }
  return out;
}
