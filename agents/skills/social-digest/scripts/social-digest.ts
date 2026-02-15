#!/usr/bin/env bun
/*
  social-digest.ts (CLI)

  Fetch daily posts from Discord + Mastodon.
  Outputs JSON to stdout.

  Env:
    DISCORD_BOT_TOKEN
    MASTODON_TOKEN
    MASTODON_BASE_URL (optional)
*/

import { parseArgs, jstDateRange, stripHtml, parseMastodonAcct, extractUrls } from "../src/socialDigest";

type DiscordMessage = any;

type Output = {
  ok: true;
  ymd: string;
  range: { start: string; end: string };
  discord: null | { channelId: string; messages: Array<{ id: string; timestamp: string; author: any; content: string; url: string; links: string[] }> };
  mastodon: null | { acct: string; baseUrl: string; statuses: Array<{ id: string; created_at: string; url: string; content_text: string; links: string[] }> };
};

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

async function discordFetchMessagesPaged(
  channelId: string,
  opts: { start: Date; end: Date; pageLimit?: number; maxPages?: number }
): Promise<DiscordMessage[]> {
  const token = process.env.DISCORD_BOT_TOKEN;
  if (!token) throw new Error("DISCORD_BOT_TOKEN is required");

  const pageLimit = Math.max(1, Math.min(100, opts.pageLimit ?? 100));
  const maxPages = Math.max(1, Math.min(5000, opts.maxPages ?? 1000));

  const out: DiscordMessage[] = [];
  let before: string | undefined;

  // Discord returns newest-first. We paginate backwards using `before` until the oldest fetched message
  // is older than start (meaning we've fully covered the day window).
  for (let pageNo = 0; pageNo < maxPages; pageNo++) {
    const url = new URL(`https://discord.com/api/v10/channels/${channelId}/messages`);
    url.searchParams.set("limit", String(pageLimit));
    if (before) url.searchParams.set("before", before);

    let res = await fetch(url.toString(), {
      headers: {
        Authorization: `Bot ${token}`,
        "User-Agent": "openclaw-social-digest (https://openclaw.ai)",
      },
    });

    // Respect rate limits.
    if (res.status === 429) {
      const data = await res.json().catch(() => null as any);
      const retryAfterMs = Math.ceil(((data?.retry_after ?? 1) as number) * 1000);
      await sleep(Math.min(60000, Math.max(250, retryAfterMs)));
      res = await fetch(url.toString(), {
        headers: {
          Authorization: `Bot ${token}`,
          "User-Agent": "openclaw-social-digest (https://openclaw.ai)",
        },
      });
    }

    if (!res.ok) {
      const t = await res.text().catch(() => "");
      throw new Error(`Discord API error ${res.status}: ${t}`);
    }

    const page: DiscordMessage[] = await res.json();
    if (!page.length) break;

    out.push(...page);
    before = page[page.length - 1]?.id;

    const oldestTs = new Date(page[page.length - 1]?.timestamp);
    if (oldestTs < opts.start) break;

    // If Discord returned fewer than requested, we've hit the beginning.
    if (page.length < pageLimit) break;
  }

  return out;
}

async function mastodonResolveAccountId(acct: string): Promise<{ baseUrl: string; id: string }>{
  const token = process.env.MASTODON_TOKEN;
  if (!token) throw new Error("MASTODON_TOKEN is required");

  const { baseUrl: inferred } = parseMastodonAcct(acct);
  const baseUrl = process.env.MASTODON_BASE_URL || inferred;

  // Try verify_credentials first.
  const verify = await fetch(`${baseUrl}/api/v1/accounts/verify_credentials`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (verify.ok) {
    const me = await verify.json();
    return { baseUrl, id: me.id };
  }

  // Fallback: search.
  const q = encodeURIComponent(acct);
  const search = await fetch(`${baseUrl}/api/v2/search?q=${q}&type=accounts&resolve=true&limit=5`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!search.ok) {
    const t = await search.text().catch(() => "");
    throw new Error(`Mastodon search error ${search.status}: ${t}`);
  }
  const data = await search.json();
  const acc = (data.accounts || []).find((a: any) => a.acct === acct);
  if (!acc) throw new Error(`Could not resolve Mastodon account for ${acct}`);
  return { baseUrl, id: acc.id };
}

async function mastodonFetchStatusesPaged(
  baseUrl: string,
  accountId: string,
  opts: { start: Date; end: Date; pageLimit?: number; maxPages?: number }
): Promise<any[]> {
  const token = process.env.MASTODON_TOKEN;
  if (!token) throw new Error("MASTODON_TOKEN is required");

  const pageLimit = Math.max(1, Math.min(40, opts.pageLimit ?? 40));
  const maxPages = Math.max(1, Math.min(2000, opts.maxPages ?? 200));

  const out: any[] = [];
  let max_id: string | undefined;

  for (let pageNo = 0; pageNo < maxPages; pageNo++) {
    const url = new URL(`${baseUrl}/api/v1/accounts/${accountId}/statuses`);
    url.searchParams.set("limit", String(pageLimit));
    url.searchParams.set("exclude_replies", "false");
    url.searchParams.set("exclude_reblogs", "false");
    if (max_id) url.searchParams.set("max_id", max_id);

    const res = await fetch(url.toString(), { headers: { Authorization: `Bearer ${token}` } });
    if (!res.ok) {
      const t = await res.text().catch(() => "");
      throw new Error(`Mastodon statuses error ${res.status}: ${t}`);
    }

    const page = await res.json();
    if (!Array.isArray(page) || page.length === 0) break;

    out.push(...page);
    max_id = page[page.length - 1]?.id;

    const oldestTs = new Date(page[page.length - 1]?.created_at);
    if (oldestTs < opts.start) break;

    if (page.length < pageLimit) break;
  }

  return out;
}

export async function run(argv = process.argv): Promise<Output> {
  const args = parseArgs(argv);
  const { ymd, start, end } = jstDateRange(args.date);

  const out: Output = {
    ok: true,
    ymd,
    range: { start: start.toISOString(), end: end.toISOString() },
    discord: null,
    mastodon: null,
  };

  if (args.discordChannel) {
    const msgs = await discordFetchMessagesPaged(args.discordChannel, {
      start,
      end,
      pageLimit: 100,
      maxPages: 2000,
    });

    const daily = msgs
      .filter((m: any) => {
        const t = new Date(m.timestamp);
        return t >= start && t < end;
      })
      .sort((a: any, b: any) => +new Date(a.timestamp) - +new Date(b.timestamp));

    out.discord = {
      channelId: args.discordChannel,
      messages: daily
        .map((m: any) => {
          const content = (m.content || "").trim();
          return {
            id: m.id,
            timestamp: m.timestamp,
            author: { id: m.author?.id, username: m.author?.username, global_name: m.author?.global_name },
            content,
            url: `https://discord.com/channels/${m.guild_id || "@me"}/${args.discordChannel}/${m.id}`,
            links: extractUrls(content),
          };
        })
        .filter((m: any) => m.content),
    };
  }

  if (args.mastodonAcct) {
    const { baseUrl, id } = await mastodonResolveAccountId(args.mastodonAcct);
    const statuses = await mastodonFetchStatusesPaged(baseUrl, id, {
      start,
      end,
      pageLimit: 40,
      maxPages: 200,
    });
    const daily = statuses
      .filter((s: any) => {
        const t = new Date(s.created_at);
        return t >= start && t < end;
      })
      .sort((a: any, b: any) => +new Date(a.created_at) - +new Date(b.created_at));

    out.mastodon = {
      acct: args.mastodonAcct,
      baseUrl,
      statuses: daily
        .map((s: any) => {
          const content_text = stripHtml(s.content || "");
          return {
            id: s.id,
            created_at: s.created_at,
            url: s.url || s.uri,
            content_text,
            links: extractUrls(content_text),
          };
        })
        .filter((s: any) => s.content_text),
    };
  }

  return out;
}

if (import.meta.main) {
  run()
    .then((out) => {
      console.log(JSON.stringify(out, null, 2));
    })
    .catch((err) => {
      console.error(err?.stack || String(err));
      process.exit(1);
    });
}
