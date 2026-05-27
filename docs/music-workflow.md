# Music CD Ripping & Management Workflow

CD ripping to Navidrome streaming on B450M-Pro4.

## System Components

| Tool | Role | Config |
|---|---|---|
| [abcde](https://abcde.einval.com/) | CD ripping (FLAC) | `applications/abcde/` |
| [beets](https://beets.io/) | Tag enrichment & organization | `applications/beets/` |
| [Navidrome](https://www.navidrome.org/) | Music streaming server | `systems/nixos/services/navidrome/` |
| [Traefik](https://traefik.io/) | Reverse proxy | `systems/nixos/services/traefik/` |

- **Inbox**: `/srv/bulk/music/_inbox/`
- **Library**: `/srv/bulk/music/`
- **Navidrome URL**: `https://music.home.yutakobayashi.com`

## 1. CD Ripping

```bash
abcde -N
```

- `-N`: non-interactive mode (auto-accepts first CDDB/MusicBrainz match)
- Manual input required if no online match is found
- Auto-ejects on completion; insert next CD and run `abcde -N` again
- Output: `/srv/bulk/music/_inbox/` (`artist/album/track title.flac`)

## 2. Tag Enrichment & Organization

```bash
beet import /srv/bulk/music/_inbox
```

- Interactive track matching with MusicBrainz
- Fetches accurate metadata, album art (`fetchart` + `embedart`)
- Computes ReplayGain tags (`replaygain`)
- Moves files from `_inbox/` to organized library
- Config: `~/.config/beets/config.yaml`

For existing files without ReplayGain:

```bash
beet replaygain
```

## 3. Play on Navidrome

Navidrome auto-scans and music is available at `https://music.home.yutakobayashi.com`.
