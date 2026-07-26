---
name: session-tts-volume
description: Adjust the cross-platform session-tts playback volume globally. The default is 0.8 to keep TTS quieter than other audio. Argument is a decimal in [0.0, 1.0], `status` (default), or `reset`. The setting is shared across sessions and persists across restarts.
---

# TTS volume ($ARGUMENTS)

The session-tts integration plays every chunk through a cross-platform audio player with this volume coefficient, so TTS does not dominate over other audio.

The chosen value lives at `$SESSION_TTS_HOME/volume` (by default `$XDG_STATE_HOME/session-tts/volume`) and is read for every chunk. The setting is per-user, not per-session — adjusting it affects every active and future session. A value outside `[0.0, 1.0]` is rejected; an empty file or missing file falls back to the built-in default (`0.8`).

Run the action below with the Bash tool. Default to `status` when `$ARGUMENTS` is empty.

```
session-tts-volume "$ARGUMENTS"
```

Execute the requested action and report the resulting line. No additional explanation is needed.
