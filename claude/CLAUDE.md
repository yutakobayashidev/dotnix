# Global Claude Code Settings

このファイルは全プロジェクトに共通で適用されるグローバル設定です。

## Branch Creation Policy

**CRITICAL**: 新しいブランチで作業する際は、必ず `git-wt` (git-worktree) を使用してください。

### ブランチ作成時の原則

```bash
# ❌ 使用禁止
git checkout -b feature/new-feature
git switch -c feature/new-feature

# ✅ 必ず git-wt を使用
git wt feature/new-feature
```

### git-wt コマンド一覧

```bash
$ git wt                            # List all worktrees
$ git wt --json                     # List all worktrees in JSON format
$ git wt <branch|worktree|path>     # Switch to worktree (create worktree/branch if needed)
$ git wt -d <branch|worktree|path>  # Delete worktree and branch (safe)
$ git wt -D <branch|worktree|path>  # Force delete worktree and branch
```

### 理由

- 複数ブランチの並列開発が可能
- ポート衝突を自動回避（`.envrc` による動的ポート割り当て）
- メインブランチを維持したまま作業可能
- ブランチ間の移動が高速（`cd` または `gwt` コマンド）
- 誤ってメインリポジトリを削除するリスクを軽減

### 例外

以下の場合のみ、従来の `git checkout/switch` を使用可能：
- 既存ブランチへの一時的な切り替え（確認目的など）
- hotfix など短命なブランチ
- git-wt が利用できない環境

## Coding Preferences

- 日本語で応答
- 絶対パスを使用
- 実行可能なコマンドを提示
