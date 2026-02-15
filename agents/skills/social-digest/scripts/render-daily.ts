#!/usr/bin/env bun

import { renderDaily, type DailyNote } from "../src/renderDaily";

async function readStdin(): Promise<string> {
  const chunks: Uint8Array[] = [];
  for await (const c of Bun.stdin.stream()) chunks.push(c);
  return Buffer.concat(chunks).toString("utf8");
}

async function main() {
  const input = await readStdin();
  if (!input.trim()) throw new Error("No JSON provided on stdin");
  const note = JSON.parse(input) as DailyNote;
  const md = renderDaily(note);
  process.stdout.write(md);
}

main().catch((err) => {
  console.error(err?.stack || String(err));
  process.exit(1);
});
