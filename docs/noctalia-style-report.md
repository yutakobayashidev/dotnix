# Niri / Noctalia デスクトップの外観調査

調査日: 2026-10-10。対象は dotnix の `feat/noctalia`、コミット `eb22218b`。このレポートは設定コードと同梱ドキュメントの調査結果であり、実際のデスクトップを並べた目視比較ではない。以下の比較は調査時点の記録。末尾に実装状況を追記した。

## 推奨する仕上がり

**Catppuccin Mocha に色を統一し、余白のある上部バーと、控えめな角丸・透明感を組み合わせる案を推奨する。** 既存の Niri、Noctalia、Vicinae、Codexbar を使ったまま実現を目指せる。まず色と情報量を整え、その後で壁紙連動やアニメーションを検討する。

参照先から取り入れたいのは、T4ko の共通パレット、Siokonbu の小さな余白と半透明のバー、moons の壁紙管理である。ただし3人とも複数アプリの設定を組み合わせているため、Noctalia の設定だけをコピーして同じ外観になるわけではない。

## 参照リポジトリの比較

調査時点のコミットを固定して記録した。表の「特徴」は設定からの解釈で、作者が掲げたデザイン方針ではない。

| リポジトリ                                                                                                            | 調査コミット | 設定から読み取れる特徴                                 | 特に参考になる要素                                     |
| --------------------------------------------------------------------------------------------------------------------- | ------------ | ------------------------------------------------------ | ------------------------------------------------------ |
| [moons-14/dotfiles](https://github.com/moons-14/dotfiles/tree/69077e06382bbba20194302312702abedfc2fbc2)               | `69077e06`   | 壁紙に追従するシェルと、Dracula 系の端末・GTK          | アイコン中心の表示、壁紙ディレクトリの再現性           |
| [T4ko0522/dotfiles](https://github.com/T4ko0522/dotfiles/tree/709ed4df141eb5b8c91f10a0406e6aff437ce12c)               | `709ed4df`   | Mocha 配色、丸い島型バー、グラデーションのフォーカス枠 | 共通パレット、バーのまとまり、余白                     |
| [Siokonbu966/nixos-config](https://github.com/Siokonbu966/nixos-config/tree/219c394c8e322873b5a5bf89e91ecd879ad22876) | `219c394c`   | 壁紙由来の暗色、細い余白、枠なし角丸                   | 控えめな透明感、中央ワークスペース、日本語対応フォント |

### moons: 壁紙連動と固定テーマの併用

Noctalia は `theme.source = "wallpaper"`、モードは `auto`。バーの両端余白は15で、中央にランチャーとワークスペースを配置する。タスクバーのタイトル、輝度とマイク音量のラベルを非表示にし、空のワークスペースも隠している。一方、CPU・RAM・通信・タスクバーも置くため、項目数自体は多い。[Noctalia 設定](https://github.com/moons-14/dotfiles/blob/69077e06382bbba20194302312702abedfc2fbc2/modules/applications/noctalia/home.nix)

Niri の角丸は8、フォーカス色は紫 `#bd93f9`。GTK は Dracula と Papirus-Dark、Ghostty も Dracula で不透明度0.9を指定する。シェルのテンプレート連携は無効なので、端末やGTKまで壁紙色へ自動追従する構成とは区別したい。[Niri](https://github.com/moons-14/dotfiles/blob/69077e06382bbba20194302312702abedfc2fbc2/modules/applications/niri/home/nixos.nix)、[GTK](https://github.com/moons-14/dotfiles/blob/69077e06382bbba20194302312702abedfc2fbc2/modules/applications/gtk/home.nix)、[Ghostty](https://github.com/moons-14/dotfiles/blob/69077e06382bbba20194302312702abedfc2fbc2/modules/applications/ghostty/home/common.nix)

壁紙は別リポジトリのリビジョンを固定して取得し、`~/.wallpapers` に配置する。60秒ごとのランダム切り替えも設定されている。dotnix では、まず現在の画像フォルダーをピッカーの対象にし、切り替えは手動にする案が扱いやすい。60秒という周期はそのまま採用する必要がない。[壁紙設定](https://github.com/moons-14/dotfiles/blob/69077e06382bbba20194302312702abedfc2fbc2/modules/applications/noctalia/home.nix)

### T4ko: 配色の共通化と島型バー

共通パレットに背景 `#1e1e2e`、文字 `#cdd6f4`、mauve `#cba6f7`、lavender `#b4befe` などを定義している。Niri は余白14、角丸10、通常の枠を無効化し、フォーカス枠を青からピンクへの45度グラデーションにする。フォーカス枠幅4.6と白い影は存在感が強い設定である。[共通色](https://github.com/T4ko0522/dotfiles/blob/709ed4df141eb5b8c91f10a0406e6aff437ce12c/nix-configs/lib/theme.nix)、[Niri](https://github.com/T4ko0522/dotfiles/blob/709ed4df141eb5b8c91f10a0406e6aff437ce12c/nix-configs/home/modules/desktop/niri.nix)

上部バーは **Waybar** である。本体を透明にし、各グループに背景不透明度0.95、角丸15、細い枠を付ける。ワークスペースは非アクティブを点状、アクティブを長いカプセルとして見せる。これが「島が浮いている」印象につながる構成である。[Waybar 構成](https://github.com/T4ko0522/dotfiles/blob/709ed4df141eb5b8c91f10a0406e6aff437ce12c/nix-configs/home/modules/desktop/waybar.nix)、[CSS](https://github.com/T4ko0522/dotfiles/blob/709ed4df141eb5b8c91f10a0406e6aff437ce12c/nix-configs/home/modules/desktop/waybar/files/style.css)

Noctalia のバーと壁紙は無効で、実際の壁紙は独自の linux-wallpaperengine 連携が担当する。Noctalia は通知やコントロールセンター、左側の自動非表示ドックなどに使われる。dotnix には共通色と丸いグループの考え方を取り入れ、動画壁紙や別バーの追加は初期案から外す。[Noctalia](https://github.com/T4ko0522/dotfiles/blob/709ed4df141eb5b8c91f10a0406e6aff437ce12c/nix-configs/home/modules/desktop/noctalia/config.toml)、[壁紙](https://github.com/T4ko0522/dotfiles/blob/709ed4df141eb5b8c91f10a0406e6aff437ce12c/nix-configs/home/modules/desktop/wallpaper.nix)

GTK は adw-gtk3-dark、カーソルは Chiffon の24。端末には PlemolJP Console NF を採用し、WezTerm は Mocha、不透明度0.7。一方、Quick Shell 用 Ghostty は0.92で、同じリポジトリでも用途によって透明度が違う。[外観](https://github.com/T4ko0522/dotfiles/blob/709ed4df141eb5b8c91f10a0406e6aff437ce12c/nix-configs/home/modules/desktop/appearance.nix)、[WezTerm配色](https://github.com/T4ko0522/dotfiles/blob/709ed4df141eb5b8c91f10a0406e6aff437ce12c/nix-configs/home/modules/apps/wezterm/files/appearance.lua)、[WezTerm書体・透明度](https://github.com/T4ko0522/dotfiles/blob/709ed4df141eb5b8c91f10a0406e6aff437ce12c/nix-configs/home/modules/apps/wezterm/files/wezterm.lua)、[Quick Shell](https://github.com/T4ko0522/dotfiles/blob/709ed4df141eb5b8c91f10a0406e6aff437ce12c/nix-configs/home/modules/desktop/quick-shell/files/ghostty.conf)

### Siokonbu: 壁紙由来の色と枠を抑えた画面

Noctalia は壁紙由来の色と `tonal-spot`、ダークモードを使用する。`Rose Pine Moon` という名前も指定されているが、壁紙抽出を有効にしているため固定配色として扱わない。バーは背景不透明度0.93、上下左右余白4、間隔6、枠なし。ワークスペースを中央に置き、UIの書体には日本語対応の Gen Interface JP を使う。[Noctalia 設定](https://github.com/Siokonbu966/nixos-config/blob/219c394c8e322873b5a5bf89e91ecd879ad22876/home/programs/noctalia/default.nix)

Niri は余白8、角丸12で、focus-ring と border を無効化する。GTK は Adwaita-dark と Papirus。Ghostty は saffron／freesia 向け設定で不透明度0.8、書体には Mononoki Nerd Font と Kosugi Maru を指定している。dotnix に採用するなら、枠をすべて消す前に、薄いフォーカスリングを残してキーボード操作時の判別性を確認したい。[Niri](https://github.com/Siokonbu966/nixos-config/blob/219c394c8e322873b5a5bf89e91ecd879ad22876/configs/niri/config.kdl)、[GTK](https://github.com/Siokonbu966/nixos-config/blob/219c394c8e322873b5a5bf89e91ecd879ad22876/home/programs/gtk/default.nix)、[Ghostty](https://github.com/Siokonbu966/nixos-config/blob/219c394c8e322873b5a5bf89e91ecd879ad22876/home/programs/ghostty/config.nix)

この参照先は `legacy-v4` の `programs.noctalia-shell` を使う。dotnix の `programs.noctalia` 5.2.1 とは設定形式が違う。余白・不透明度・配置の値を参考にし、キー名はv5の仕様に合わせる。[flake](https://github.com/Siokonbu966/nixos-config/blob/219c394c8e322873b5a5bf89e91ecd879ad22876/flake.nix)

## dotnix の現状と改善余地

### 配色が同じ Catppuccin 内で分かれている

Noctalia の `builtin = "Catppuccin"` は、使用中の5.2.1では暗色背景 `#1e1e2e`、主色 `#cba6f7` の Mocha 系である。一方、Ghostty は `Catppuccin Macchiato`、Niri のフォーカス色は `#f5bde6`、swaylock の背景は `#24273a`。名称は近くても、青みと明るさ、アクセント色が異なる。[Noctalia の実装](https://github.com/noctalia-dev/noctalia/blob/v5.2.1/src/theme/builtin_palettes.cpp)、[現行 Noctalia](../modules/features/window-manager/noctalia/default.nix)、[Ghostty](../modules/features/terminal/ghostty/default.nix)、[Niri](../modules/features/window-manager/niri/default.nix)、[swaylock](../modules/features/window-manager/swaylock/default.nix)

Mocha に統一すれば Noctalia の組み込みテーマをそのまま使える。Macchiato を残す場合は、Noctalia のカスタムパレットを宣言する方法もあるが、管理する色定義が増える。まずMochaを採用し、差し色をmauveかピンクのどちらかに絞る案が小さな変更で済む。Ghosttyではテーマ名に加え、明示した `cursor-color`、`cursor-text`、`selection-background`、`selection-foreground` も更新または削除する必要がある。[カスタムパレット仕様](https://github.com/noctalia-dev/noctalia/blob/v5.2.1/docs/user/theming/palette.mdx)

### バーの右側へ情報が集中している

現在は右側に16エントリーがあり、うち2つはスペーサー。CPU・RAM・輝度・マイク音量・出力音量・時計などが並ぶ。中央はメディア表示なので、再生の有無で中央の情報量も変わる。これは設定上の項目数であり、実画面でのはみ出しを確認したものではない。[現行バー](../modules/features/window-manager/noctalia/default.nix)

提案は、ワークスペースを中央に固定し、CPU・RAM・輝度・マイク音量を常設から外すこと。これらの操作や状態確認はパネル側に残し、Codexbar は日常的に見る固有情報として維持する。privacy 表示も残す。時計を `10/10 21:30` 程度に短縮し、曜日や年はツールチップへ移す。

配置の概念図。幅やアイコンの描画を再現したモックアップではない。

```text
左: Vicinae · Codexbar       中央: ● ━ ●       右: Tray · 通知 · Privacy · Wi-Fi · 音量 · 電池 · 時計 · 設定
```

### 角丸・透明度・アプリ外観を揃えられる

Niri は余白16、窓の角丸10。一方、Noctalia は `corner_radius_scale = 0.2` と丸みをかなり抑えている。これは倍率なので、Niri の10pxと直接比較はできない。Noctalia の標準倍率に戻してバーの半径を明示すると、調整対象を把握しやすい。

Ghostty の不透明度0.75は壁紙がよく見える設定だが、画像の模様が文字と重なる可能性もある。最初は0.90〜0.95に上げ、明るい部分の多い壁紙でもコードが読みやすいかを見る。GTK・Qt・アイコンテーマについては、今回のリポジトリ検索では共通の外観指定を確認できなかった。GTK暗色設定とアイコンを明示する余地がある。ただしlibadwaitaアプリまで同じテーマになるとは限らない。[現行端末](../modules/features/terminal/ghostty/default.nix)、[フォント](../systems/nixos/fonts.nix)

## 具体的な変更案と優先順位

以下は参照先の値そのものではなく、dotnix 用の開始案。工数は実装とローカル評価の目安であり、パッケージのビルド待ちを含まない。

| 優先 | 変更案                     | 開始値・方針                                                                 | 想定工数 |
| ---- | -------------------------- | ---------------------------------------------------------------------------- | -------- |
| 1    | パレットを統一             | Mocha、背景 `#1e1e2e`、文字 `#cdd6f4`、差し色 `#cba6f7`                      | 30〜60分 |
| 1    | バーの情報量を整理         | 中央ワークスペース、常設項目を削減、Codexbarは維持                           | 30〜60分 |
| 1    | バーを画面端から離す       | `margin_ends=12`、`margin_edge=8`、`thickness=34`、`radius=12`、不透明度0.95 | 30分程度 |
| 2    | 窓とパネルの形を揃える     | Niri余白12・角丸12、フォーカスリング2、通常のborderは明示的に無効            | 30〜60分 |
| 2    | 端末の読みやすさを調整     | Ghostty不透明度0.92、既存padding14×12と日本語フォールバック維持              | 15〜30分 |
| 2    | GTK・アイコンを統一        | 暗色、Papirus-Dark等を比較。UI Inter＋Noto Sans CJK JPは維持                 | 30〜60分 |
| 3    | 壁紙選択とOverviewを整える | `~/wallpapers`をピッカーに指定、静止画・手動変更、Overview背景を確認         | 30〜60分 |
| 3    | 軽いぼかし・動きを追加     | 設定の対応確認後に対象を限定し、電池駆動でも比較                             | 1〜2時間 |

Noctalia v5にはバーの余白・半径・不透明度・カプセル設定がある。また、ワークスペースの `style = "focus_hint"` で非アクティブを点、アクティブを長い表示にできる。T4ko のWaybar CSSをそのまま再現する約束はせず、まず「浮いた1本のバー＋ワークスペースのカプセル」で近い印象を作る。[バー仕様](https://github.com/noctalia-dev/noctalia/blob/v5.2.1/docs/user/bar/index.mdx)、[ワークスペース仕様](https://github.com/noctalia-dev/noctalia/blob/v5.2.1/docs/user/bar/widgets/workspaces.mdx)

変更場所は既存の [Noctalia](../modules/features/window-manager/noctalia/default.nix)、[Niri](../modules/features/window-manager/niri/default.nix)、[Ghostty](../modules/features/terminal/ghostty/default.nix)、[壁紙](../modules/features/desktop/wallpaper/default.nix) が中心になる。Ghostty はmacOSとも共有するので、Linux向けの透明度調整を他ホストへ波及させるかは実装時に区別する。まず数か所の値を合わせ、共通色が実際に重複する範囲だけ小さなパレット定義へまとめる。

## 別案: 壁紙に合わせてシェルの色を変える

画像を変える楽しさを優先するなら、moons・Siokonbu寄りの壁紙連動案がある。v5では `theme.source = "wallpaper"`、`theme.mode = "dark"`、`theme.wallpaper_scheme = "m3-tonal-spot"` を開始案にする。まずバー・パネルだけを連動させ、端末は落ち着いた固定暗色に保つと変更範囲を小さくできる。[v5テーマ仕様](https://github.com/noctalia-dev/noctalia/blob/v5.2.1/docs/user/theming/index.mdx)

全アプリの自動同期は別の実装段階になる。Noctaliaの組み込みテンプレートは、Ghosttyでは設定ファイルの `theme` 行を変更し、Niriでは設定ファイルへ `include` を追加する処理を持つ。Home Managerが管理するファイルに対して、そのまま書き込ませる構成は避ける。採用時は、Nix側でincludeやthemeの参照を宣言し、Noctalia側には生成先を所有させる設計と動作確認が必要になる。[Ghostty apply処理](https://github.com/noctalia-dev/noctalia/blob/v5.2.1/assets/templates/ghostty/apply.sh)、[Niri apply処理](https://github.com/noctalia-dev/noctalia/blob/v5.2.1/assets/templates/niri/apply.sh)

## 導入時の確認項目

1. **まずThinkPadで比較する。** 同じ壁紙、同じウィンドウ配置、同じ1.5倍スケールで変更前後を撮る。バーの文字量、長い曲名、通知、日本語表示を確認する。
2. **システム全体を評価する。** Home Managerの値だけでなく、ThinkPadとUM790-Proの `system.build.toplevel.drvPath` を評価する。Niriの生成設定も対応する実行ファイルで検証する。
3. **描画と操作を確認する。** アクティブ窓の判別、フルスクリーン、Overview、複数画面、Vicinae、音量・輝度キー、Codexbarを確認する。
4. **動的な効果は後から比較する。** 固定中のnixpkgsではNiriは26.04で、Noctalia同梱資料は26.04以降のぼかしを説明する。ただしNix側の設定スキーマと生成結果の対応確認はまだ行っていない。Ghostty側のblur指定だけで有効になるとは扱わない。[Niri連携資料](https://github.com/noctalia-dev/noctalia/blob/v5.2.1/docs/user/compositor-settings/niri.mdx)
5. **既存の電源・ロック構成を維持する。** 今回の外観変更に、power-profiles-daemon、別のバー、別の壁紙デーモン、ロック機構の置き換えを混ぜる必要はない。

## 実装状況（2026-10-10）

推奨案のうち、Mocha共通パレット、中央ワークスペースと簡潔なバー、余白・角丸12、Linux Ghosttyの不透明度0.92、swaylockの配色、GTK暗色とPapirus-Dark、壁紙ピッカーの `~/wallpapers` 指定を実装した。再生中メディアの表示はバー左側に保持し、Control Centerのショートカットからも操作できるようにした。CPU/RAM・マイク・輝度も同パネルからアクセスする。macOSのGhostty設定は維持する。

動的配色、追加のぼかし・アニメーション、Overviewの変更は後続候補として残す。システムへの適用と実画面での確認は未実施。
