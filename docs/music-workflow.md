# Music CD Ripping & Management Workflow

B450M-Pro4 での CD リッピングから Navidrome 配信までの一連の流れ。

## システム構成

| ツール                                  | 役割                 | 設定場所                            |
| --------------------------------------- | -------------------- | ----------------------------------- |
| [abcde](https://abcde.einval.com/)      | CD リッピング (FLAC) | `applications/abcde/`               |
| [beets](https://beets.io/)              | タグ補完・整理       | `applications/beets/`               |
| [Navidrome](https://www.navidrome.org/) | 音楽配信サーバー     | `systems/nixos/services/navidrome/` |
| [Nextcloud](https://nextcloud.com/)     | ファイルストレージ   | `systems/nixos/services/nextcloud/` |
| [Traefik](https://traefik.io/)          | リバースプロキシ     | `systems/nixos/services/traefik/`   |

- **MusicFolder**: `/var/lib/nextcloud/data/yuta/files/music/`
- **Navidrome URL**: `https://music.home.yutakobayashi.com`

## 1. CD リッピング

```bash
exec sg cdrom zsh
abcde -N
```

- `-N`: 非インタラクティブモード（CDDB の最初のマッチを自動採用）
- CDDB が存在しない場合は手動入力が必要
- 終了後自動イジェクト → 次の CD を入れて `abcde -N` 繰り返し
- 出力先: `/var/lib/nextcloud/data/yuta/files/music/` (アーティスト/アルバム/トラック番号 曲名.flac)

## 2. タグ補完・整理

```bash
beet import -A /var/lib/nextcloud/data/yuta/files/music
```

- `-A`: オートインポート（トラックマッチをインタラクティブに確認）
- MusicBrainz から正確なメタデータを取得しタグ補完
- アルバムアートの自動取得・埋め込み (`fetchart` + `embedart` プラグイン)
- 設定は `~/.config/beets/config.yaml`

## 3. Nextcloud にインデックス

```bash
sudo -u nextcloud php /run/nextcloud/occ files:scan --path="/yuta/files/music"
```

## 4. Navidrome で再生

インデックス後、Navidrome が自動スキャン → `https://music.home.yutakobayashi.com` で聴ける。
