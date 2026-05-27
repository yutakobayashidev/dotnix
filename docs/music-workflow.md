# Music CD Ripping & Management Workflow

CD ripping to Navidrome streaming on B450M-Pro4.

## System Components

| Tool | Role | Config |
|---|---|---|
| [whipper](https://github.com/whipper-team/whipper) | CD ripping (FLAC, AccurateRip) | `applications/whipper/` |
| [beets](https://beets.io/) | Tag enrichment & organization | `applications/beets/` |
| [Navidrome](https://www.navidrome.org/) | Music streaming server | `systems/nixos/services/navidrome/` |
| [Traefik](https://traefik.io/) | Reverse proxy | `systems/nixos/services/traefik/` |

- **Inbox**: `/srv/bulk/music/_inbox/`
- **Library**: `/srv/bulk/music/`
- **Navidrome URL**: `https://music.home.yutakobayashi.com`

## 1. CD Ripping

```bash
whipper cd rip
```

- Matches CD against MusicBrainz, rips with AccurateRip verification
- Auto-ejects on success
- Cover art fetched and embedded (`cover_art = file,embed`)
- Output: `/srv/bulk/music/_inbox/` (`artist/album/track title.flac`)

## 2. Tag Enrichment & Organization

```bash
beet import /srv/bulk/music/_inbox
```

- Interactive track matching with MusicBrainz
- Fetches accurate metadata, album art (`fetchart` + `embedart`)
- Computes ReplayGain tags (`replaygain` with ffmpeg backend)
- Moves files from `_inbox/` to organized library
- Config: `~/.config/beets/config.yaml`

For existing files without ReplayGain:

```bash
beet replaygain
```

## 3. Play on Navidrome

Navidrome auto-scans and music is available at `https://music.home.yutakobayashi.com`.
