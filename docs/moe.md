# moe: net pics and gallery-dl Immich

`moe.home.yutakobayashi.com` is the dedicated net pics and gallery-dl Immich instance on
B450M-Pro4. Personal photos remain in `photos.home.yutakobayashi.com`.

The NixOS OCI module runs four Podman containers: `moe-server`,
`moe-machine-learning`, `moe-database`, and `moe-redis`. Traefik connects to
`127.0.0.1:2284`. The other containers have no published ports. Images are pinned
and follow the [Immich v3.3.3 release compose file](https://github.com/immich-app/immich/releases/download/v3.3.3/docker-compose.yml).

## HDD storage

| Host path                    | Contents                                        |
| ---------------------------- | ----------------------------------------------- |
| `/srv/bulk/moe/library`      | Uploads, thumbnails, encoded videos, backups    |
| `/srv/bulk/moe/postgres`     | Dedicated PostgreSQL database                   |
| `/srv/bulk/moe/model-cache`  | Machine-learning models                         |
| `/srv/bulk/moe/redis`        | Valkey data                                     |
| `/srv/bulk/moe/database.env` | Generated DB credentials, root-only mode 0600   |
| `/var/lib/immich-net-pics`   | Existing HDD originals written by bookmark snap |
| `/srv/bulk/gallery-dl`       | Existing HDD originals downloaded by gallery-dl |

Credentials are generated once, directly in their persistent location. Back up
`database.env` with the database and library, and restore them together. Deleting
this file does not rotate an existing database's password.

All persistent application data is on HDD. Container image layers and logs use
the host's existing Podman storage. Services require the HDD mounts before
creating directories or starting containers. PostgreSQL uses `DB_STORAGE_TYPE=HDD`.

## Activation and migration from photos

1. Apply with `nix run .#switch` on B450M-Pro4.
2. Open `https://moe.home.yutakobayashi.com` and create the administrator account.
3. In Administration → External Libraries, create a library for that user with
   import path `/external/net-pics`. This is the read-only mount of the existing
   originals. Exclude `**/temp-*` and `**/temp-*/**` to omit bookmark snap's
   temporary render frames and staging directories, then scan the library.
4. Configure periodic library scans in Administration. Verify that a newly saved
   bookmark image appears after a scan.
   Create a separate gallery-dl library with import path
   `/external/gallery-dl/pixiv/bookmarks` to match the existing photos collection.
   The entire `/srv/bulk/gallery-dl` tree is mounted read-only at
   `/external/gallery-dl`; add other subdirectories only when they should also
   appear in moe. Exclude `**/*.part` and scan the library.
5. Compare asset counts and open representative images and videos. Albums,
   favorites, descriptions, and other metadata stored only in the old database
   are not transferred by this scan.
6. Back up the old Immich database. In `photos`, identify the library with import
   path `/var/lib/immich-net-pics`. After verifying `moe`, remove that library's
   registration through Immich library management. Confirm originals still exist
   and personal photos remain visible. If that library contains other paths, or
   net pics were uploaded rather than registered as an external library, inspect
   that arrangement before removal.
   Repeat the verification and removal for the library containing
   `/srv/bulk/gallery-dl/pixiv/bookmarks`. Remove only these external library
   registrations; uploaded personal photos stay in photos.

“External library” describes how Immich accesses originals managed by another
program. These assets appear in the main timeline; net pics is the main
collection in `moe`. Bookmark snap keeps writing the same directory. See
[Immich external libraries](https://docs.immich.app/features/libraries/).

Do not delete `/var/lib/immich-net-pics` or `/srv/bulk/gallery-dl` when removing
the old registrations.

## Repairing bookmark snapshots

Bookmark snap checks existing PNG/MP4 files with ffmpeg instead of treating any
existing file as completed. New media is rendered into a temporary directory on
the same filesystem, decoded, then atomically renamed into place. Failure leaves
the previous output intact and makes the job exit nonzero. The scheduled unit
also requires the output filesystem mount.

The Nix build patches twitter-snap 0.0.81 to accept `TWITTER_SNAP_RELAY_URL`
(the relay origin) and an optional `TWITTER_SNAP_RELAY_PROFILE`. The service sets
only the URL: rendering uses Safe Relay's default random account selection.
Bookmark enumeration remains pinned to `account2`. Generated authentication
headers are omitted so the relay supplies its own credentials. With no relay URL,
the library retains its normal guest behavior.

To repair old files independently of the bookmark pagination cutoff, first apply
the configuration, then run from the repository root:

```sh
snap_app=$(systemctl show twitter-bookmark-snap.service --property=WorkingDirectory --value)
export TWITTER_SNAP_RELAY_URL=https://tw.home.yutakobayashi.com
nix shell .#nixosConfigurations.B450M-Pro4.pkgs.nodejs .#nixosConfigurations.B450M-Pro4.pkgs.ffmpeg \
  --command node "$snap_app/dist/index.js" --repair --output-dir /var/lib/immich-net-pics
```

`--repair --limit 1` selects one damaged tweet for a pilot. For a full repair,
omit `--limit`: repeatedly running limited batches can get stuck retrying the
same unavailable posts. Only numeric tweet filenames are considered; temporary
files are ignored. Requests are sequential with a two-second delay. Originals
that cannot be fetched remain unchanged, and failures are logged with tweet IDs.
An out-of-space filesystem error stops the run.

After repair, rescan the library in moe and rerun failed thumbnail jobs as needed.
Do not remove the old photos registration until recovery results are checked.

## Verification

```sh
systemctl status moe-setup podman-moe-{server,database,redis,machine-learning}
journalctl -u podman-moe-server -n 100 --no-pager
findmnt -T /srv/bulk/moe/library
findmnt -T /var/lib/immich-net-pics
```
