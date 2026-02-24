# zsh/functions

`~/.config/zsh/functions/*.zsh` として自動読み込みされるシェル関数群。

## 一覧

| 関数 | 説明 | 使い方 |
|------|------|--------|
| `ashiba` | ghq create + nix flake init でプロジェクト雛形作成 | `ashiba [--local] <name> [template]` |
| `cd-up` | 親ディレクトリに移動（Alt+Up にバインド） | キーバインド |
| `claude-zai` | Z.AI API プロキシ経由で Claude Code を実行 | `claude-zai [args]` |
| `ct` | Claude Code を tmux teammate mode で起動 | `ct [args]` |
| `dev` | tmux ベースのマルチプロジェクト開発セッション管理 | `dev [subcommand]` |
| `g` | 引数なし: ghq+peco でリポジトリ移動、引数あり: git | `g [git args]` |
| `gb` | fzf でブランチを検索・チェックアウト | `gb` |
| `gh-q` | GitHub リポジトリを検索・clone | `gh-q [-o] [owner]` |
| `git-wt-clean` | マージ済み worktree とブランチを一括削除 | `git-wt-clean` |
| `gwt` | fzf で git worktree を検索・移動 | `gwt` |
| `jb` | fzf で jj bookmark を選択・new | `jb` |
