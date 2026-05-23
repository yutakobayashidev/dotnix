---
name: youtube-transcript
description: Extract transcripts, captions, or subtitles from YouTube videos. Use when the user provides a YouTube URL or video ID and asks for a transcript, optionally with timestamps, or asks to save captions to a file.
user-invocable: true
---

# YouTube Transcript

## Purpose

Fetch a YouTube video's transcript using `youtube-transcript-api`.

Reference: https://gist.github.com/intellectronica/6178110791dc19a05d7c0173118fd48e

## Run

```bash
nix-shell -p 'python312.withPackages (ps: [ ps.youtube-transcript-api ])' --run 'python {baseDir}/scripts/get_transcript.py "VIDEO_URL_OR_ID"'
```

With timestamps:

```bash
nix-shell -p 'python312.withPackages (ps: [ ps.youtube-transcript-api ])' --run 'python {baseDir}/scripts/get_transcript.py "VIDEO_URL_OR_ID" --timestamps'
```

Save to a file:

```bash
nix-shell -p 'python312.withPackages (ps: [ ps.youtube-transcript-api ])' --run 'python {baseDir}/scripts/get_transcript.py "VIDEO_URL_OR_ID" --timestamps' > transcript.txt
```

## Output Rules

- Do not alter transcript wording.
- Without timestamps, it is acceptable to rewrap lines into complete paragraphs if the user asked for readable text.
- With timestamps, preserve one caption segment per line.
- If the user asks to save the transcript, write it to the requested path.
- If no output file is specified but a file is needed, use `<video-id>-transcript.txt`.

## Supported Inputs

- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://youtube.com/embed/VIDEO_ID`
- `https://youtube.com/v/VIDEO_ID`
- Raw 11-character video ID

## Notes

- Captions must be available on the video.
- The script first tries the default transcript fetch, then falls back to the first available transcript language.
