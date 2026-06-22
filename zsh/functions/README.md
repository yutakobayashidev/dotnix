# zsh/functions

`~/.config/zsh/functions/*.zsh` として自動読み込みされるシェル関数群。

## 一覧

| 関数         | 説明                                              | 使い方                       |
| ------------ | ------------------------------------------------- | ---------------------------- |
| `branch`     | fzf でブランチを選択・作成して切り替え            | `branch [git branch args]`   |
| `cd-up`      | 親ディレクトリに移動（Alt+Up にバインド）         | キーバインド                 |
| `cdf`        | 最近移動したディレクトリを fzf で選択して移動     | `cdf [query]`                |
| `claude-zai` | Z.AI API プロキシ経由で Claude Code を実行        | `claude-zai [args]`          |
| `ct`         | Claude Code を tmux teammate mode で起動          | `ct [args]`                  |
| `dev`        | tmux ベースのマルチプロジェクト開発セッション管理 | `dev [subcommand]`           |
| `cdg`        | Git リポジトリのルートへ移動                      | `cdg`                        |
| `fpull`      | fetch 後に必要なら stash して pull                | `fpull`                      |
| `g`          | 引数なし: ghq+fzf でリポジトリ移動、引数あり: git | `g [git args]`               |
| `gb`         | fzf でブランチを検索・チェックアウト              | `gb`                         |
| `ghauth`     | ghtkn の認証コードをクリップボードへコピー        | `ghauth [args]`              |
| `gifit`      | fzf でコミット範囲を選んで `difit` を実行         | `gifit`                      |
| `gip`        | グローバルIPアドレスを表示                        | `gip`                        |
| `gh-q`       | GitHub リポジトリを検索・clone                    | `gh-q [-o] [owner]`          |
| `jb`         | fzf で jj bookmark を選択・new                    | `jb`                         |
| `nfi`        | nix flake init with fuzzy template selection      | `nfi <flake_ref> [template]` |
| `stash`      | タイムスタンプ付きで git stash save               | `stash [message]`            |
| `worktree`   | fzf で git worktree を検索・移動                  | `worktree`                   |

`Ctrl+G` でも `g` の引数なしと同じ `ghq + fzf` のリポジトリ選択 UI を開ける。
