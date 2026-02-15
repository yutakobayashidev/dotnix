import { describe, test, expect } from "bun:test";
import { renderDaily } from "../src/renderDaily";

describe("renderDaily", () => {
  test("renders the 2026-02-10 structure", () => {
    const md = renderDaily({
      created: "2026-02-10T05:00:00+09:00",
      ymd: "2026-02-10",
      tags: ["social-digest", "discord"],
      sources: { discordChannelId: "1028287639918497822", mastodonAcct: "yuta@fedi.yutakobayashi.com" },
      counts: { discordMessages: 1, mastodonStatuses: 0, linksRead: 0 },
      memos: [],
      links: [],
      rawTitle: "2026-02-10",
      raw: { discord: [{ tsJst: "2026-02-10 00:00 JST", authorId: "123", body: "hello" }], mastodon: [] },
    });

    expect(md).toContain("# Social Digest (2026-02-10)");
    expect(md).toContain("## Sources");
    expect(md).toContain("## Counts");
    expect(md).toContain("## Memos (from posts)");
    expect(md).toContain("## Links read");
    expect(md).toContain("## Raw (2026-02-10)");
    expect(md).toContain("(123)");
  });
});
