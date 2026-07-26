---
name: session-tts
description: Toggle TTS playback for the current agent session. TTS is ON by default at session start; use this skill to silence the current session, re-enable it, or check its status. Argument is one of `on`, `off`, `toggle`, or `status` (default `status`). Other concurrent sessions are unaffected.
---

# TTS toggle ($ARGUMENTS)

Codex reads responses aloud via `Stop` and `PermissionRequest` hooks. A `SessionStart` hook assigns this session a voice and marks it ON automatically, so every new session speaks by default. This skill is the override path: silence the current session, re-enable after silencing, or check status.

The voice assigned to this session is decided once at SessionStart and stays the same even after `session-tts off`/`session-tts on` — only playback is gated.

The silence flag lives under `$SESSION_TTS_HOME/silenced/$SESSION_TTS_SESSION_ID` (by default `$XDG_STATE_HOME/session-tts`). When present, the dispatcher skips playback for this session. Other concurrent sessions stay as they are. Switching to `off` (directly or via `toggle`) additionally terminates any utterance that is still playing for this session, so the silence takes effect immediately rather than draining the current chunk queue.

Run the action below with the Bash tool. Default to `status` when `$ARGUMENTS` is empty.

```
session-tts-tts "$ARGUMENTS"
```

Execute the requested action and report the resulting line. No additional explanation is needed.
