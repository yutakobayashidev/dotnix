# Lessons

## 2026-02-26: gh-poi が git worktree 対応済み → git-wt-clean は不要

- `gh-poi` はマージ済みブランチの worktree 自動削除、locked worktree スキップ、linked worktree 上での実行をサポート済み
- `git-wt-clean` は `git branch -vv` の `gone` フラグ（追跡先リモートブランチが削除済み）に依存していたが、これは upstream 未設定のブランチを検出できず、削除理由も区別できない
- `gh-poi` は GitHub API で PR 状態を直接確認するため、より正確で安全
- 自前スクリプトを書く前に、既存ツールの最新機能を確認すること
