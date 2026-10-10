# MPRIS media history on ThinkPad

`my.services.mpris-collector.enable` is enabled only on
`ThinkPad-X1-Carbon-Gen13`. The `mpris-media-logger` user service starts with the
graphical session. It observes session D-Bus; no server, account, or uploader is
required. It never controls playback or captures media audio/video.

## Reference and format

[Aurboda's client recipe](https://github.com/fiddur/aurboda/issues/1155) separates a
Python/Gio logger writing JSONL from a timer posting batches to `/api/sync/media`.
This collector independently implements the local half. Its flat records match
[Aurboda's MediaPlayInput](https://github.com/fiddur/aurboda/blob/257fa0a5d68fc5012fdec5dce76744b5a2149bcd/packages/api-spec/src/schemas/sync.ts#L534).
The local contract is [schema.json](../modules/features/productivity/mpris-collector/schema.json)
(v1). Do not change field meanings when adding an uploader.

Default output: `$XDG_STATE_HOME/mpris-media/plays.jsonl`, normally
`~/.local/state/mpris-media/plays.jsonl`. Directory/file permissions for newly
created data are 0700/0600. A file lock prevents two collectors writing the same
journal. A partial final line from an interrupted write is removed on startup;
complete invalid lines cause a visible failure rather than silently skipping data.

Example record (illustrative):

```json
{
	"id": "27e57c24f3a44d65ae96bb9d246760fe",
	"device": "ThinkPad-X1-Carbon-Gen13",
	"player": "firefox.instance123",
	"url": "https://example.org/video",
	"title": "Workout video",
	"artist": "",
	"album": "",
	"started_at": "2026-10-11T01:00:00.000000+00:00",
	"ended_at": "2026-10-11T01:02:00.000000+00:00",
	"played_secs": 110.0,
	"track_secs": 1800.0,
	"max_position_secs": 300.0,
	"seek_count": 1
}
```

| Field                             | Meaning                                                                        |
| --------------------------------- | ------------------------------------------------------------------------------ |
| `id`                              | UUID per observed play; stable across checkpoints                              |
| `device`, `player`                | Hostname and MPRIS name without prefix, retaining instance suffix              |
| `url`, `title`, `artist`, `album` | Player metadata; absent strings stay empty; artists joined with comma-space    |
| `started_at`, `ended_at`          | UTC observation boundaries, not necessarily the media's actual start/end       |
| `played_secs`                     | Sum of accepted Position advances while previously Playing, in content seconds |
| `track_secs`                      | Positive reported length in seconds; null if absent/invalid                    |
| `max_position_secs`               | Furthest reported position, including seeks; zero if never available           |
| `seek_count`                      | Seek signals and inferred discontinuities, reconciled when possible            |

No `kind`, `played_ratio`, or activity classification is invented. Aurboda adds
`source=mpris` and `record_type=media_play` at ingestion; these are not input fields.
Future uploads can wrap latest records as `{"device_name":"...","plays":[...]}`
(up to 1000 records per Aurboda request).

## Checkpoints and interpretation

**JSONL is an append-only revision log, not one distinct play per line.** Every
60 seconds the cumulative record is checkpointed with the same ID, and it is
written again when stopped, changed, disconnected, or shut down. Readers must
keep the **last line per ID**. Never sum all lines. A checkpoint's `ended_at` means
"observed through", not confirmed completion. There is no final/completed flag.

```sh
jq -s 'reduce .[] as $play ({}; .[$play.id] = $play) | [.[]]' ~/.local/state/mpris-media/plays.jsonl
```

After restart a new ID is used; earlier checkpoints remain valid partial history.
An abrupt crash can lose up to roughly 60 seconds of uncheckpointed observations
under normal polling. There is no automatic deletion or rotation yet; monitor
file size and stop the service before moving the journal.

The collector polls every 5 seconds because Position does not emit regular
PropertiesChanged signals. Metadata/status and Seeked signals also trigger
sampling. `playerctld` is excluded because it mirrors other players. Multiple
real player instances are kept separately, even if they play the same content.

Rate is used to distinguish plausible progression from jumps. Paused time and
known seeks are not counted. Stop resetting Position to zero is not a seek.
A gap longer than 15 seconds, including suspend, ends the old segment at its last
observation and starts a new one if still playing. Unavailable players similarly
end at the last successful sample.

These remain estimates: short unreported seeks can look like playback; a seek
may discard up to a sampling interval of legitimate progress. Track switches and
shutdown do not invent the unobserved tail. Missing Position produces no credited
seconds (possibly zero), **not proof that nothing played**. This compatibility
schema cannot express measurement coverage; use a separate future observation
schema if raw samples/quality flags are needed. Replays may exceed track length;
neither elapsed interval nor played seconds proves human attention or completion.

## Apply and verify

On the ThinkPad, apply the checkout with `nix run .#switch`, then:

```sh
systemctl --user start mpris-media-logger
systemctl --user status mpris-media-logger
journalctl --user -u mpris-media-logger -n 30
```

Play media in a supported Firefox/mpv/Spotify session for at least 10 seconds,
pause/resume, seek, then stop. Check the JSONL (it contains private titles/URLs):

```sh
tail -n 3 ~/.local/state/mpris-media/plays.jsonl | jq .
```

If the file is empty, confirm the player exposes MPRIS on the user session bus.
Unsupported apps and inactive browser tabs may expose no media. Use
`systemctl --user stop mpris-media-logger` to pause collection and `start` to resume.
The CLI also supports `--output PATH` and `--device NAME`; stop the service before
running it manually against the same file.

## Tests

Use Python with `pygobject3`, `jsonschema`, and test-only `dbus-next`, with GLib's
`lib/girepository-1.0` on `GI_TYPELIB_PATH`:

```sh
cd modules/features/productivity/mpris-collector
python3 -m unittest test_collector -v
dbus-run-session -- python3 -m unittest test_dbus -v
```

The unit tests cover pauses, rates, seeks, stopped resets, track changes, missing
positions, checkpoints, suspend, concurrent players, schema, and journal recovery.
The integration test uses an isolated real session bus and a fake MPRIS player.
It does not demonstrate compatibility with every application on the ThinkPad.
