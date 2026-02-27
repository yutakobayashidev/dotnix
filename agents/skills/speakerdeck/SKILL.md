---
name: speakerdeck
description: Download slide images from a SpeakerDeck presentation. Use when the user provides a SpeakerDeck URL and wants to read, summarize, or convert the slides.
user-invocable: true
---

# SpeakerDeck Scraper

## Purpose

Download all slide images from a SpeakerDeck presentation URL. Zero dependencies — uses only built-in fetch and fs APIs. The downloaded images can be read by Claude Vision or converted with `markitdown`.

## Run

```bash
BUN_BE_BUN=1 claude {baseDir}/scripts/speakerdeck.ts <speakerdeck-url> [-o output-dir]
```

### Arguments

| Arg | Description |
|-----|-------------|
| `<url>` | SpeakerDeck presentation URL (required) |
| `-o, --output <dir>` | Output directory (default: `$TMPDIR/speakerdeck-<id>/`) |

### Output (JSON to stdout)

```json
{
  "title": "Presentation Title",
  "presentationId": "abc123def456",
  "slideCount": 30,
  "outputDir": "/tmp/speakerdeck-abc123def456",
  "files": ["/tmp/speakerdeck-abc123def456/slide_000.jpg", "..."]
}
```

## Workflow Examples

### Read slides with Claude Vision

```bash
result=$(BUN_BE_BUN=1 claude {baseDir}/scripts/speakerdeck.ts "https://speakerdeck.com/user/talk")
# Then use the file paths from the JSON output with Read tool
```

### Convert to Markdown with markitdown

```bash
result=$(BUN_BE_BUN=1 claude {baseDir}/scripts/speakerdeck.ts "https://speakerdeck.com/user/talk")
dir=$(echo "$result" | jq -r '.outputDir')
for f in "$dir"/*.jpg; do markitdown "$f"; done
```

## How It Works

1. Fetches the SpeakerDeck page HTML to extract the presentation ID (from the player iframe URL)
2. Binary-search probes the CDN (`files.speakerdeck.com`) to determine slide count
3. Downloads all slide JPEGs (5 concurrent)

## Notes

- Images are 1920x1080 JPEG from SpeakerDeck's CDN
- Zero external dependencies — runs with `BUN_BE_BUN=1 claude` (no bun/node install needed)
- Private or password-protected presentations are not supported
