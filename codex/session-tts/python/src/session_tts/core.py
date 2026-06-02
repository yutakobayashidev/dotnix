"""Speak text aloud via the remote TTS engine API.

Core text=audio adapter. Receives the text to speak on stdin (plain UTF-8)
and the per-session voice via the SESSION_TTS_SPEAKER_ID env var.
"""

from __future__ import annotations

import os
import queue
import re
import signal
import subprocess
import sys
import tempfile
import threading

import httpx

ENGINE_BASE_URL = os.environ.get("SESSION_TTS_ENGINE_URL", "http://127.0.0.1:10101")
SPEAKER_ID = int(os.environ.get("SESSION_TTS_SPEAKER_ID", "0"))
SESSION_ID = os.environ.get("SESSION_TTS_SESSION_ID", "")

MAX_TEXT_LENGTH = 2000
FIRST_CHUNK_MAX = 60
LATER_CHUNK_MAX = 250

FAST_SPEED_CHUNK_THRESHOLD = 4
FAST_SPEED_SCALE = 1.2

MAX_CHUNKS = 8
TRUNCATION_NOTICE = "以下、省略します。"

DEFAULT_PLAYBACK_VOLUME = 0.8
VOLUME_FILE = os.path.expanduser("~/.codex/session-tts/volume")


def resolve_playback_volume() -> str:
    try:
        with open(VOLUME_FILE) as f:
            raw = f.read().strip()
        value = float(raw)
    except (FileNotFoundError, ValueError, OSError):
        return f"{DEFAULT_PLAYBACK_VOLUME:.2f}"
    if not 0.0 <= value <= 1.0:
        return f"{DEFAULT_PLAYBACK_VOLUME:.2f}"
    return f"{value:.2f}"


PIDFILE_DIR = os.path.expanduser("~/.codex/session-tts/playback")
PIDFILE = os.path.join(PIDFILE_DIR, SESSION_ID) if SESSION_ID else ""


# --- text cleanup ----------------------------------------------------------


def _strip_inline_markdown(text: str) -> str:
    text = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]*)\)", r"\1", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    text = re.sub(r"\*([^*]+)\*", r"\1", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    for ch in ["#", ">"]:
        text = text.replace(ch, "")
    text = re.sub(r"\s*https?://[^\s。．！？、，]+", "", text)
    text = re.sub(r"\.(?=\S)", " ", text)
    text = re.sub(r"(?<!\w)!(?=\w)", "", text)
    text = re.sub(r"[—\u2013\u2014\u2500\u2501]{2,}", " ", text)
    return " ".join(text.split()).strip()


_LIST_ITEM_RE = re.compile(r"^([-*+]\s+|\d+\.\s+)(.*)")
_TERMINAL_PUNCT = ("。", "．", "！", "？", "!", "?", ".", "、", "，", ",")

_HEADING_LINE_RE = re.compile(r"^#{1,6}\s+\S")


def clean(text: str) -> str:
    paragraphs = re.split(r"\n[ \t]*\n+", text)
    out: list[str] = []
    in_code = False
    pending_heading = ""
    for paragraph in paragraphs:
        lines = paragraph.split("\n")
        is_heading_only = (
            not in_code
            and len(lines) == 1
            and _HEADING_LINE_RE.match(lines[0].strip()) is not None
        )
        cleaned: list[str] = []
        for line in lines:
            s = line.strip()
            if s.startswith("```"):
                in_code = not in_code
                continue
            if in_code:
                continue
            if s.startswith("$ ") or s.startswith("> "):
                continue
            if line.startswith("    ") and s:
                continue
            if "|" in s:
                continue
            if s.startswith("---") or s.startswith(":--"):
                continue
            list_match = _LIST_ITEM_RE.match(s)
            if list_match:
                item_text = list_match.group(2).strip()
                if not item_text:
                    continue
                if cleaned and not cleaned[-1].endswith(_TERMINAL_PUNCT):
                    cleaned[-1] += "。"
                if not item_text.endswith(_TERMINAL_PUNCT):
                    item_text += "。"
                cleaned.append(item_text)
            elif s:
                cleaned.append(s)
        if not cleaned:
            continue
        merged = _strip_inline_markdown(" ".join(cleaned))
        if not merged:
            continue
        if is_heading_only:
            if not merged.endswith(_TERMINAL_PUNCT):
                merged += "。"
            pending_heading += merged
            continue
        if pending_heading:
            merged = pending_heading + merged
            pending_heading = ""
        out.append(merged)
    if pending_heading:
        out.append(pending_heading)
    return "\n\n".join(out)[:MAX_TEXT_LENGTH]


# --- chunking --------------------------------------------------------------


def _force_split(text: str, max_chars: int) -> list[str]:
    out: list[str] = []
    while len(text) > max_chars:
        split_at = text.rfind(" ", 0, max_chars + 1)
        if split_at <= 0:
            out.append(text[:max_chars])
            text = text[max_chars:]
        else:
            out.append(text[: split_at + 1])
            text = text[split_at + 1 :]
    if text:
        out.append(text)
    return out


def _split_paragraph(text: str, max_chars: int) -> list[str]:
    parts = re.split(r"(?<=[。．！？!?.])", text)
    chunks: list[str] = []
    for part in parts:
        if not part:
            continue
        if len(part) > max_chars:
            chunks.extend(_force_split(part, max_chars))
        else:
            chunks.append(part)
    return chunks


def split_into_chunks(text: str) -> list[str]:
    chunks: list[str] = []
    pending_separator = ""
    for paragraph in re.split(r"(\n\n+)", text):
        if paragraph.startswith("\n\n"):
            pending_separator += paragraph
            continue
        paragraph = pending_separator + paragraph
        pending_separator = ""
        if not paragraph.strip():
            continue
        if not chunks:
            head = _split_paragraph(paragraph, FIRST_CHUNK_MAX)
            if head:
                chunks.append(head[0])
                if len(head) > 1:
                    rest = "".join(head[1:])
                    chunks.extend(_split_paragraph(rest, LATER_CHUNK_MAX))
        else:
            chunks.extend(_split_paragraph(paragraph, LATER_CHUNK_MAX))
    if chunks and pending_separator:
        chunks[-1] += pending_separator
    return chunks


# --- single-flight playback ------------------------------------------------


def kill_previous_playback() -> None:
    if not PIDFILE:
        return
    try:
        with open(PIDFILE) as f:
            old_pgid = int(f.read().strip())
    except (FileNotFoundError, ValueError):
        return
    try:
        os.killpg(old_pgid, signal.SIGTERM)
    except (ProcessLookupError, PermissionError):
        pass


def register_self() -> None:
    os.setpgrp()
    if not PIDFILE:
        return
    os.makedirs(os.path.dirname(PIDFILE), exist_ok=True)
    with open(PIDFILE, "w") as f:
        f.write(str(os.getpid()))


def clear_self() -> None:
    if not PIDFILE:
        return
    try:
        with open(PIDFILE) as f:
            recorded = int(f.read().strip())
        if recorded == os.getpid():
            os.unlink(PIDFILE)
    except (FileNotFoundError, ValueError):
        pass


# --- synthesis & playback --------------------------------------------------


def synth_chunk(
    client: httpx.Client, text: str, speaker_id: int, speed_scale: float = 1.0
) -> bytes:
    q = client.post("/audio_query", params={"text": text, "speaker": speaker_id})
    q.raise_for_status()
    query = q.json()
    if speed_scale != 1.0:
        query["speedScale"] = speed_scale
    query["prePhonemeLength"] = 0.5
    s = client.post(
        "/synthesis",
        params={"speaker": speaker_id},
        json=query,
        timeout=120.0,
    )
    s.raise_for_status()
    return s.content


def player_worker(play_queue: "queue.Queue[str | None]") -> None:
    while True:
        path = play_queue.get()
        if path is None:
            return
        subprocess.run(
            ["afplay", "--volume", resolve_playback_volume(), path], check=False
        )
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass


def synth_worker(
    client: httpx.Client,
    speaker_id: int,
    chunks: list[str],
    play_queue: "queue.Queue[str | None]",
) -> None:
    speed_scale = FAST_SPEED_SCALE if len(chunks) >= FAST_SPEED_CHUNK_THRESHOLD else 1.0
    try:
        for chunk in chunks:
            try:
                wav_bytes = synth_chunk(client, chunk, speaker_id, speed_scale)
            except httpx.HTTPError:
                continue
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                f.write(wav_bytes)
                path = f.name
            play_queue.put(path)
    finally:
        play_queue.put(None)


# --- entrypoint ------------------------------------------------------------


def main() -> None:
    if SPEAKER_ID == 0:
        return
    text = sys.stdin.read()
    if not text:
        return

    text = clean(text)
    if not text:
        return

    chunks = split_into_chunks(text)
    if not chunks:
        return
    if len(chunks) > MAX_CHUNKS:
        chunks = chunks[:MAX_CHUNKS] + [TRUNCATION_NOTICE]

    kill_previous_playback()
    register_self()
    try:
        with httpx.Client(base_url=ENGINE_BASE_URL, timeout=60.0) as client:
            play_queue: "queue.Queue[str | None]" = queue.Queue()
            synth_thread = threading.Thread(
                target=synth_worker,
                args=(client, SPEAKER_ID, chunks, play_queue),
                daemon=False,
            )
            player_thread = threading.Thread(
                target=player_worker, args=(play_queue,), daemon=False
            )
            synth_thread.start()
            player_thread.start()
            synth_thread.join()
            player_thread.join()
    finally:
        clear_self()


if __name__ == "__main__":
    main()
