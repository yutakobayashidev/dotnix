#!/usr/bin/env bun

// Resolve an X/Twitter status URL (or id) via FixTweet API.
// Usage:
//   bun run scripts/fxtweet.ts --url "https://x.com/jack/status/20?lang=ja"
//   bun run scripts/fxtweet.ts --id "20" --screen "jack" --lang "ja"

import { rewriteUrlForFetch } from "../src/socialDigest";

type Args = { url?: string; id?: string; screen?: string; lang?: string };

function parseArgs(argv: string[]): Args {
  const out: Args = {};
  for (let i = 2; i < argv.length; i++) {
    const k = argv[i];
    const v = argv[i + 1];
    if (!k.startsWith("--")) continue;
    if (v && !v.startsWith("--")) {
      (out as any)[k.slice(2)] = v;
      i++;
    } else {
      (out as any)[k.slice(2)] = "true";
    }
  }
  return out;
}

async function main() {
  const a = parseArgs(process.argv);

  let apiUrl = "";
  if (a.url) {
    apiUrl = rewriteUrlForFetch(a.url);
  } else if (a.id) {
    const screen = a.screen || "status";
    const lang = a.lang || "ja";
    apiUrl = `https://api.fxtwitter.com/${screen}/status/${a.id}/${lang}`;
  } else {
    throw new Error('Usage: --url <x-url> OR --id <tweetId> [--screen <name>] [--lang ja]');
  }

  const res = await fetch(apiUrl);
  if (!res.ok) {
    const t = await res.text().catch(() => "");
    throw new Error(`FixTweet API error ${res.status}: ${t}`);
  }
  const data = await res.json();
  console.log(JSON.stringify({ apiUrl, ...data }, null, 2));
}

main().catch((e) => {
  console.error(e instanceof Error ? e.message : String(e));
  process.exit(1);
});
