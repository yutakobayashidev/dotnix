# Music CD Ripping & Management Workflow

CD ripping to Navidrome streaming on B450M-Pro4.

## System Components

| Tool                                    | Role                          | Config                              |
| --------------------------------------- | ----------------------------- | ----------------------------------- |
| [abcde](https://abcde.einval.com/)      | CD ripping (FLAC)             | `applications/abcde/`               |
| [beets](https://beets.io/)              | Tag enrichment & organization | `applications/beets/`               |
| [Navidrome](https://www.navidrome.org/) | Music streaming server        | `systems/nixos/services/navidrome/` |
| [Nextcloud](https://nextcloud.com/)     | File storage                  | `systems/nixos/services/nextcloud/` |
| [Traefik](https://traefik.io/)          | Reverse proxy                 | `systems/nixos/services/traefik/`   |

- **MusicFolder**: `/var/lib/nextcloud/data/yuta/files/music/`
- **Navidrome URL**: `https://music.home.yutakobayashi.com`

## 1. CD Ripping

```bash
exec sg cdrom zsh
abcde -N
```

- `-N`: non-interactive mode (auto-accepts first CDDB/MusicBrainz match)
- Manual input required if no online match is found
- Auto-ejects on completion; insert next CD and run `abcde -N` again
- Output: `/var/lib/nextcloud/data/yuta/files/music/` (`artist/album/track title.flac`)

## 2. Tag Enrichment & Organization

```bash
beet import -A /var/lib/nextcloud/data/yuta/files/music
```

- `-A`: auto-import with interactive track matching
- Fetches accurate metadata from MusicBrainz and writes tags
- Auto-fetches and embeds album art (`fetchart` + `embedart` plugins)
- Config: `~/.config/beets/config.yaml`

## 3. Nextcloud Re-index

```bash
sudo -u nextcloud php /run/nextcloud/occ files:scan --path="/yuta/files/music"
```

## 4. Play on Navidrome

After indexing, Navidrome auto-scans and music is available at `https://music.home.yutakobayashi.com`.
