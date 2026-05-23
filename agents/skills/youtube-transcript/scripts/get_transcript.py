#!/usr/bin/env python3
"""Extract a transcript from a YouTube video."""

# Based on intellectronica's YouTube transcript skill:
# https://gist.github.com/intellectronica/6178110791dc19a05d7c0173118fd48e

import argparse
import re
import sys

from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._errors import NoTranscriptFound


def extract_video_id(url_or_id: str) -> str:
    """Extract a YouTube video ID from common URL formats or a raw ID."""
    patterns = [
        r"(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/|youtube\.com/v/)([a-zA-Z0-9_-]{11})",
        r"^([a-zA-Z0-9_-]{11})$",
    ]

    for pattern in patterns:
        match = re.search(pattern, url_or_id)
        if match:
            return match.group(1)

    raise ValueError(f"Could not extract video ID from: {url_or_id}")


def format_timestamp(seconds: float) -> str:
    """Convert seconds to HH:MM:SS or MM:SS format."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)

    if hours > 0:
        return f"{hours:02d}:{minutes:02d}:{secs:02d}"

    return f"{minutes:02d}:{secs:02d}"


def get_transcript(video_id: str, with_timestamps: bool = False) -> str:
    """Fetch and format transcript text for a YouTube video."""
    api = YouTubeTranscriptApi()

    try:
        transcript = api.fetch(video_id)
    except NoTranscriptFound:
        transcript_list = api.list(video_id)
        first = next(iter(transcript_list))
        print(
            f"Note: English transcript not available. Using: {first.language} ({first.language_code})",
            file=sys.stderr,
        )
        transcript = first.fetch()

    if with_timestamps:
        lines = [
            f"[{format_timestamp(snippet.start)}] {snippet.text}"
            for snippet in transcript.snippets
        ]
    else:
        lines = [snippet.text for snippet in transcript.snippets]

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Get a YouTube video transcript")
    parser.add_argument("video", help="YouTube video URL or video ID")
    parser.add_argument(
        "--timestamps", "-t", action="store_true", help="Include timestamps in output"
    )
    args = parser.parse_args()

    try:
        video_id = extract_video_id(args.video)
        transcript = get_transcript(video_id, with_timestamps=args.timestamps)
        print(transcript)
    except Exception as error:
        print(f"Error: {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
