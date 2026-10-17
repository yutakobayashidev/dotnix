# Immich storage investigation — 2026-10-17

Read-only investigation following the split of net pics into `moe`. No originals,
database records, or old library registrations were removed during this audit.

## Findings

| Scope                                          | Result                                                                                                                              |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `photos` active uploaded assets                | All 2,275 DB-referenced originals exist and are nonempty                                                                            |
| `/var/lib/immich/library`                      | 2,274 files, zero empty files (includes one `.immich` marker)                                                                       |
| `/var/lib/immich/upload`                       | 116 empty media files; none referenced by current asset original paths, and none matched an asset ID with another nonempty original |
| `/var/lib/immich-net-pics`, excluding `temp-*` | 1,061 empty PNGs; 353 nonempty PNGs pass signature, chunk CRC, IEND and zlib-stream checks; seven nonempty MP4s                     |
| net pics MP4s                                  | Six pass ffprobe container/duration inspection; `2081371458052534508.mp4` fails with `moov atom not found`                          |
| net pics temporary files                       | 67 empty PNGs, one nonempty PNG, one nonempty MP4                                                                                   |
| `/srv/bulk/gallery-dl`                         | 22,683 files; only empty file is an unfinished `.jpg.part` download                                                                 |
| Btrfs HDD counters                             | Read, write, flush, corruption and generation error counters are all zero                                                           |
| HDD free space                                 | Approximately 271.5 GiB at audit time                                                                                               |
| Existing Immich DB backups                     | Daily compressed SQL backups Oct 4–17; latest passes `gzip -t`                                                                      |

The old database contains 26,228 assets: 2,275 uploaded assets, 1,490 external
assets under net pics (including temporary files), and 22,463 external assets
outside the initial path allowlist. Samples from the latter point into
`/srv/bulk/gallery-dl/pixiv/bookmarks`. The subsequent filesystem scan checks
nonempty files there, but does not establish that every DB path exists.

The 1,128 zero-byte external DB entries are dated 2026. No nonempty derivative
file was found for those entries by the audit's recognized-path mapping.
The 116 unreferenced upload files have modification dates July 2, 6 and 10;
these are media extensions, not management markers. Their original creation
cause is not proven.

## Cause evidence

- Retained bookmark snap logs contain 895 `ENOSPC` rendering failures on July
  26–28 involving 71 distinct tweet IDs. Of those IDs, 53 currently have empty
  PNGs. Two sampled files' modification timestamps exactly match their logged
  write failures.
- The invalid MP4 also has a recorded ffmpeg conversion failure on July 28.
- The renderer writes directly to final paths. A failed write can leave an
  empty or incomplete file.
- `hasRenderedTweet` tests only file existence, so empty/incomplete output is
  subsequently treated as completed. Five consecutive existing outputs stop
  fetching. Per-render failures are caught and the process still exits zero.
- These facts establish a persistence/retry bug and explain observed cases;
  retained logs do not establish the cause of every empty file. Empty net pics
  files have modification/change dates across July 2–27 and August 18.
- Git history configured the HDD net pics mount on May 28, before this incident.
  The new moe container mounts originals read-only and has separate state.

## Limits and remaining work

Recovery implementation now validates media with ffmpeg and atomically replaces
only successfully decoded output. Its Nix build runs storage and relay tests.
A guest-based recovery pass repaired 101 files after a separate one-file pilot.
Ten attempts failed before that pass was stopped to switch transport. One of
those failures (`2057793412074721716`) rendered successfully through Safe Relay,
including with no profile header (the relay's default random selection).
Thus `No data` from guest retrieval does not establish that a post is deleted.
The replacement user unit `twitter-bookmark-snap-repair-relay.service` finished
all 962 selected tweets at 01:26 JST on October 18: 874 rendered successfully
and 88 failed with `No data`. Its nonzero exit reflects those failures, not an
interrupted run. The failed IDs are saved outside the repository in
`~/.local/state/twitter-bookmark-snap/failed-tweet-ids-2026-10-18.txt`.
Those posts are not yet proven unrecoverable. The NixOS switch was applied and
the scheduled service was verified to use the patched build with the relay URL
and no fixed rendering profile.

- Nonempty personal originals have not all been decoded or checksum-verified.
  This is evidence against widespread zero-byte loss, not proof every photo is
  intact. The net pics MP4 check is container inspection, not full playback.
- Zero Btrfs error counters do not substitute for SMART diagnostics or a scrub.
  The script produced no SMART result because `smartctl` was unavailable.
- SQL backups preserve database contents, not image originals. Only a Gitea
  snapshot appeared in the HDD snapshot list. Other/off-device backups remain
  unverified.
- PostgreSQL reports a libc collation version mismatch (2.42 versus 2.44), a
  separate maintenance issue; no evidence links it to zero-byte media files.
- Keep old net pics registration until recovery/migration decisions are made.
  Recoverability depends on the source posts still being accessible.
  Do not delete the unrelated uploaded personal-photo collection.
