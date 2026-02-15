import { normalizeUrl } from "./socialDigest";

export type DailyLink = {
  title: string;
  gist: string;
  url: string; // display url
  key_points?: string[];
  headings?: string[];
};

export type DailyNote = {
  created: string; // ISO
  ymd: string; // YYYY-MM-DD
  tags: string[]; // english, lowercase, kebab-case
  sources: {
    discordChannelId: string;
    mastodonAcct: string;
  };
  counts: {
    discordMessages: number;
    mastodonStatuses: number;
    linksRead: number;
  };
  memos: string[];
  links: Array<{ section?: string; items: DailyLink[] }>;
  rawTitle?: string; // e.g. "today" or "2026-02-10" (defaults to ymd)
  raw: {
    discord: Array<{ tsJst: string; authorId?: string; body: string }>;
    mastodon: Array<{ tsJst: string; body: string }>;
  };
};

function kebabOk(tag: string): boolean {
  return /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(tag);
}

function escapeYamlSingleLine(s: string): string {
  // for ISO string etc; we keep it simple.
  return String(s).replace(/\r?\n/g, " ");
}

function flattenRaw(s: string): string {
  return String(s).replace(/\r?\n+/g, " / ").trim();
}

export function renderDaily(note: DailyNote): string {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(note.ymd)) throw new Error(`Invalid ymd: ${note.ymd}`);
  if (!note.created) throw new Error("created is required");
  if (!Array.isArray(note.tags) || note.tags.length === 0) throw new Error("tags must be non-empty");
  for (const t of note.tags) if (!kebabOk(t)) throw new Error(`Invalid tag: ${t}`);
  if (!note.tags.includes("social-digest")) throw new Error("tags must include 'social-digest'");

  const fm = [
    "---",
    `created: ${escapeYamlSingleLine(note.created)}`,
    `source: openclaw.social-digest`,
    `ymd: ${note.ymd}`,
    `tags: [${note.tags.join(", ")}]`,
    `links_read: ${note.counts.linksRead}`,
    "---",
    "",
  ].join("\n");

  const lines: string[] = [];
  lines.push(fm);
  lines.push(`# Social Digest (${note.ymd})`);
  lines.push("");

  lines.push("## Sources");
  lines.push(`- Discord: channel \`${note.sources.discordChannelId}\``);
  lines.push(`- Mastodon: \`${note.sources.mastodonAcct}\``);
  lines.push("");

  lines.push("## Counts");
  lines.push(`- Discord messages: ${note.counts.discordMessages}`);
  lines.push(`- Mastodon statuses: ${note.counts.mastodonStatuses}`);
  lines.push(`- Links read: ${note.counts.linksRead}`);
  lines.push("");

  lines.push("## Memos (from posts)");
  if (!note.memos?.length) {
    lines.push("- (no memos)");
  } else {
    for (const m of note.memos) lines.push(`- ${flattenRaw(m)}`);
  }
  lines.push("");

  lines.push("## Links read");
  const anyLinks = note.links?.some((g) => g.items?.length);
  if (!anyLinks) {
    lines.push("(no links)");
  } else {
    const groups = note.links || [];
    const hasMultipleGroups = groups.filter((g) => (g.items || []).length).length > 1;

    for (const g of groups) {
      const items = g.items || [];
      if (!items.length) continue;

      const section = (g.section || "").trim();
      const shouldPrintSection =
        section &&
        (hasMultipleGroups || section.toLowerCase() !== "links");

      if (shouldPrintSection) {
        lines.push("");
        lines.push(`### ${section}`);
      }

      for (const it of items) {
        const title = (it.title || "").trim() || "(untitled)";
        const url = normalizeUrl(it.url || "");
        lines.push("");
        lines.push(`### ${title}`);
        lines.push(`- Gist: ${(it.gist || "").trim() || "(no gist)"}`);

        const kp = (it.key_points || []).map((x) => x.trim()).filter(Boolean);
        if (kp.length) {
          lines.push("- Key points:");
          for (const p of kp) lines.push(`  - ${flattenRaw(p)}`);
        }

        const hd = (it.headings || []).map((x) => x.trim()).filter(Boolean);
        if (hd.length) {
          lines.push("- Headings:");
          for (const h of hd) lines.push(`  - ${flattenRaw(h)}`);
        }

        lines.push(`- URL: ${url}`);
      }
    }
  }
  lines.push("");

  const rawTitle = (note.rawTitle || note.ymd).trim();
  lines.push(`## Raw (${rawTitle})`);
  lines.push("### Discord");
  if (!note.raw?.discord?.length) {
    lines.push("- (no messages today)");
  } else {
    for (const r of note.raw.discord) {
      const aid = r.authorId ? ` (${r.authorId})` : "";
      lines.push(`- ${r.tsJst}${aid} — ${flattenRaw(r.body)}`);
    }
  }
  lines.push("");

  lines.push("### Mastodon");
  if (!note.raw?.mastodon?.length) {
    lines.push("- (no statuses today)");
  } else {
    for (const r of note.raw.mastodon) {
      lines.push(`- ${r.tsJst} — ${flattenRaw(r.body)}`);
    }
  }
  lines.push("");

  return lines.join("\n");
}
