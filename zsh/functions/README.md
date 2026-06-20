# zsh/functions

`~/.config/zsh/functions/*.zsh` として自動読み込みされるシェル関数群。

## 一覧

| 関数         | 説明                                              | 使い方                       |
| ------------ | ------------------------------------------------- | ---------------------------- |
| `cd-up`      | 親ディレクトリに移動（Alt+Up にバインド）         | キーバインド                 |
| `claude-zai` | Z.AI API プロキシ経由で Claude Code を実行        | `claude-zai [args]`          |
| `ct`         | Claude Code を tmux teammate mode で起動          | `ct [args]`                  |
| `dev`        | tmux ベースのマルチプロジェクト開発セッション管理 | `dev [subcommand]`           |
| `g`          | 引数なし: ghq+fzf でリポジトリ移動、引数あり: git | `g [git args]`               |
| `gb`         | fzf でブランチを検索・チェックアウト              | `gb`                         |
| `gifit`      | fzf でコミット範囲を選んで `difit` を実行         | `gifit`                      |
| `gip`        | グローバルIPアドレスを表示                        | `gip`                        |
| `gh-q`       | GitHub リポジトリを検索・clone                    | `gh-q [-o] [owner]`          |
| `W`          | fzf で git worktree を検索・移動                  | `W`                          |
| `jb`         | fzf で jj bookmark を選択・new                    | `jb`                         |
| `nfi`        | nix flake init with fuzzy template selection      | `nfi <flake_ref> [template]` |

`Ctrl+G` でも `g` の引数なしと同じ `ghq + fzf` のリポジトリ選択 UI を開ける。
