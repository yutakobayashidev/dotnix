# zsh/functions

`~/.config/zsh/functions/*.zsh` として自動読み込みされるシェル関数群。

## 一覧

| 関数         | 説明                                              | 使い方                       |
| ------------ | ------------------------------------------------- | ---------------------------- |
| `branch`     | fzf でブランチを選択・作成して切り替え            | `branch [git branch args]`   |
| `cd-up`      | 親ディレクトリに移動（Alt+Up にバインド）         | キーバインド                 |
| `cdf`        | 最近移動したディレクトリを fzf で選択して移動     | `cdf [query]`                |
| `claude-zai` | Z.AI API プロキシ経由で Claude Code を実行        | `claude-zai [args]`          |
| `cdg`        | Git リポジトリのルートへ移動                      | `cdg`                        |
| `fpull`      | fetch 後に必要なら stash して pull                | `fpull`                      |
| `g`          | 引数なし: ghq+fzf でリポジトリ移動、引数あり: git | `g [git args]`               |
| `gb`         | fzf でブランチを検索・チェックアウト              | `gb`                         |
| `ghunk`      | fzf でコミット範囲を選び Hunk で差分を表示        | `ghunk`                      |
| `gip`        | グローバルIPアドレスを表示                        | `gip`                        |
| `gh-q`       | GitHub リポジトリを検索・clone                    | `gh-q [-o] [owner]`          |
| `gqm`        | ghq の配置を remote URL に合わせて点検・移動      | `gqm [--dry-run / --apply]`  |
| `jb`         | fzf で jj bookmark を選択・new                    | `jb`                         |
| `nfi`        | nix flake init with fuzzy template selection      | `nfi <flake_ref> [template]` |
| `stash`      | タイムスタンプ付きで git stash push               | `stash [message]`            |
| `worktree`   | fzf で git worktree を検索・移動                  | `worktree`                   |

`Ctrl+G` でも `g` の引数なしと同じ `ghq + fzf` のリポジトリ選択 UI を開ける。

## ghq の配置を点検・整理する

```sh
gqm              # 点検のみ（--dry-run と同じ）
gqm --dry-run    # 移動元・移動先を表示
gqm --apply      # 移動可能な repo を確認なしで移動
```

`ghq list -p` の一覧を取得し、各 repo を `ghq migrate --dry-run` で確認する。
配置済みは件数だけを表示し、移動先の衝突や remote の取得失敗はエラーとして表示して残りを続行する。
`--apply` は点検に成功した repo に `ghq migrate -y` を実行する。
移動先を上書きせず、worktree・submodule の単独移動はスキップする。
現在の作業ディレクトリを含む repo は移動しないため、その repo の外へ `cd` して実行する。
remote URL 自体の変更は行わない。

終了コードは正常終了が `0`、点検・移動エラーが `1`、引数エラーが `2`。
移動対象があるだけなら dry-run は `0` を返す。

Nix の設定を反映した後、新しい zsh を開くと読み込まれる。反映前に試す場合は、dotnix のルートで `source zsh/functions/gqm.zsh` を実行する。
動作検証は dotnix のルートで `python3 tests/gqm.py` を実行する（ghq と zsh が必要）。
