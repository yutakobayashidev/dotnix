import { describe, expect, test } from "bun:test";
import { jstDateRange, parseArgs, stripHtml, parseMastodonAcct, extractUrls, normalizeUrl, rewriteUrlForFetch } from "../src/socialDigest";

describe("parseArgs", () => {
  test("requires --date", () => {
    expect(() => parseArgs(["bun", "x", "--out", "Daily"]))
      .toThrow(/--date is required/);
  });

  test("parses basic args", () => {
    const a = parseArgs([
      "bun",
      "x",
      "--date",
      "2026-02-10",
      "--discord-channel",
      "123",
      "--mastodon-acct",
      "yuta@fedi.yutakobayashi.com",
      "--out",
      "Daily/Social",
      "--format",
      "daily",
    ]);
    expect(a.date).toBe("2026-02-10");
    expect(a.discordChannel).toBe("123");
    expect(a.mastodonAcct).toBe("yuta@fedi.yutakobayashi.com");
    expect(a.out).toBe("Daily/Social");
    expect(a.format).toBe("daily");
  });
});

describe("jstDateRange", () => {
  test("today resolves to JST date", () => {
    // 2026-02-10 00:30 JST == 2026-02-09 15:30Z
    const now = new Date("2026-02-09T15:30:00.000Z");
    const r = jstDateRange("today", now);
    expect(r.ymd).toBe("2026-02-10");
    expect(r.start.toISOString()).toBe("2026-02-09T15:00:00.000Z");
    expect(r.end.toISOString()).toBe("2026-02-10T15:00:00.000Z");
  });

  test("rejects invalid date", () => {
    expect(() => jstDateRange("2026/02/10")).toThrow(/Invalid date/);
  });
});

describe("stripHtml", () => {
  test("strips tags and keeps newlines", () => {
    const html = "<p>Hello<br/>World</p><p>Next</p>";
    expect(stripHtml(html)).toBe("Hello\nWorld\n\nNext");
  });
});

describe("normalizeUrl", () => {
  test("removes common tracking params", () => {
    const u = "https://wired.jp/article/x?utm_source=twitter&utm_medium=social&x=1&utm_content=null";
    expect(normalizeUrl(u)).toBe("https://wired.jp/article/x?x=1");
  });
});

describe("rewriteUrlForFetch", () => {
  test("rewrites x.com status to fxtwitter api", () => {
    const u = "https://x.com/foo/status/1234567890123456789";
    expect(rewriteUrlForFetch(u)).toBe("https://api.fxtwitter.com/foo/status/1234567890123456789/ja");
  });

  test("rewrites twitter i/web status to fxtwitter api", () => {
    const u = "https://twitter.com/i/web/status/20?lang=ja";
    expect(rewriteUrlForFetch(u)).toBe("https://api.fxtwitter.com/status/status/20/ja");
  });

  test("leaves non-matching urls", () => {
    expect(rewriteUrlForFetch("https://example.com/")).toBe("https://example.com/");
  });
});

describe("extractUrls", () => {
  test("extracts and dedupes", () => {
    const t = "hey https://example.com/a). also https://example.com/a and https://foo.bar/x?y=1";
    expect(extractUrls(t)).toEqual(["https://example.com/a", "https://foo.bar/x?y=1"]);
  });

  test("returns empty for none", () => {
    expect(extractUrls("no links")).toEqual([]);
  });
});

describe("parseMastodonAcct", () => {
  test("parses username and host", () => {
    const r = parseMastodonAcct("yuta@fedi.yutakobayashi.com");
    expect(r.username).toBe("yuta");
    expect(r.host).toBe("fedi.yutakobayashi.com");
    expect(r.baseUrl).toBe("https://fedi.yutakobayashi.com");
  });

  test("rejects invalid acct", () => {
    expect(() => parseMastodonAcct("no-at-symbol")).toThrow(/Invalid mastodon acct/);
  });
});
