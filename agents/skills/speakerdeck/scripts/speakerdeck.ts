#!/usr/bin/env bun
/*
  speakerdeck.ts – Download slide images from SpeakerDeck

  No browser required. Uses fetch to extract the presentation ID from the page
  HTML and downloads slide JPEGs directly from SpeakerDeck's CDN.

  Usage:
    bun run speakerdeck.ts <url> [-o output-dir]
    ./speakerdeck <url> [-o output-dir]   (compiled binary)
*/

import { parseArgs } from "util";
import { mkdir, writeFile } from "fs/promises";
import { tmpdir } from "os";
import { join } from "path";

const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

const CDN = "https://files.speakerdeck.com/presentations";

// ── Extract presentation ID from page HTML ──

async function fetchPresentationId(url: string): Promise<{ id: string; title: string | null }> {
  const res = await fetch(url, { headers: { "User-Agent": UA } });
  if (!res.ok) throw new Error(`HTTP ${res.status} fetching ${url}`);
  const html = await res.text();

  // Title
  const titleMatch = html.match(/<title>([^<]+)<\/title>/i);
  const title = titleMatch
    ? titleMatch[1].replace(/\s*[-–|]?\s*Speaker Deck.*$/i, "").trim() || null
    : null;

  // Strategy 1: player iframe src
  const iframeMatch = html.match(/speakerdeck\.com\/player\/([a-f0-9]+)/);
  if (iframeMatch) return { id: iframeMatch[1], title };

  // Strategy 2: presentations/{id} reference
  const presMatch = html.match(/presentations\/([a-f0-9]{20,})/);
  if (presMatch) return { id: presMatch[1], title };

  throw new Error("Could not find presentation ID in page HTML");
}

// ── Binary-search for slide count ──

async function probeSlideCount(id: string): Promise<number> {
  const check = async (n: number) => {
    const res = await fetch(`${CDN}/${id}/slide_${n}.jpg`, {
      method: "HEAD",
      headers: { "User-Agent": UA },
    });
    return res.ok;
  };

  if (!(await check(0))) {
    throw new Error("Cannot access slide images – presentation may be private");
  }

  let lo = 0;
  let hi = 300;
  while (lo < hi) {
    const mid = Math.ceil((lo + hi) / 2);
    (await check(mid)) ? (lo = mid) : (hi = mid - 1);
  }
  return lo + 1;
}

// ── Main ──

const { values, positionals } = parseArgs({
  args: Bun.argv.slice(2),
  options: { output: { type: "string", short: "o" } },
  allowPositionals: true,
});

const url = positionals[0];
if (!url?.includes("speakerdeck.com")) {
  console.error("Usage: speakerdeck <speakerdeck-url> [-o output-dir]");
  process.exit(1);
}

const { id, title } = await fetchPresentationId(url);
const slideCount = await probeSlideCount(id);

console.error(`${title ?? "(untitled)"} – ${slideCount} slides`);

const outDir = values.output ?? join(tmpdir(), `speakerdeck-${id}`);
await mkdir(outDir, { recursive: true });

// Download slides (5 concurrent)
console.error("Downloading...");
const BATCH = 5;
const files: string[] = [];

for (let i = 0; i < slideCount; i += BATCH) {
  const batch = Array.from(
    { length: Math.min(BATCH, slideCount - i) },
    (_, k) => i + k,
  );
  await Promise.all(
    batch.map(async (idx) => {
      const res = await fetch(`${CDN}/${id}/slide_${idx}.jpg`, {
        headers: { "User-Agent": UA },
      });
      if (!res.ok) {
        console.error(`  Failed slide_${idx}: HTTP ${res.status}`);
        return;
      }
      const filename = `slide_${String(idx).padStart(3, "0")}.jpg`;
      const filepath = join(outDir, filename);
      await writeFile(filepath, new Uint8Array(await res.arrayBuffer()));
      files[idx] = filepath;
    }),
  );
  console.error(`  ${Math.min(i + BATCH, slideCount)}/${slideCount}`);
}

console.log(
  JSON.stringify({
    title,
    presentationId: id,
    slideCount: files.filter(Boolean).length,
    outputDir: outDir,
    files: files.filter(Boolean),
  }),
);
