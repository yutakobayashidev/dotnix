# PR Aftercare

PR を作成した後の CI 監視・レビュー対応のワークフロー。

## 1. CI Watch

PR 作成直後、CI の完了を待って結果を確認する。

```bash
gh pr checks <PR_NUMBER> --watch --fail-fast
```

- **全 pass** → 次のステップへ
- **failure** → ログを読み、原因を特定して修正。コミット & push 後に再度 watch。green になるまでループ

修正時は最小限の diff に留める。CI を通すためだけの無関係な変更を混ぜない。

## 2. Review Triage

レビューコメントの確認を依頼されたら:

```bash
# レビュースレッド一覧を取得
gh api graphql -f query='
{
  repository(owner: "<OWNER>", name: "<REPO>") {
    pullRequest(number: <NUMBER>) {
      reviewThreads(first: 50) {
        nodes {
          id
          isResolved
          comments(first: 5) {
            nodes { body author { login } }
          }
        }
      }
    }
  }
}'
```

各コメントを以下の基準で分類する:

| 分類 | 判断基準 | アクション |
|------|----------|------------|
| **即修正** | コードで対応可能、spec に影響なし | 修正してコミット |
| **spec トレードオフ** | 修正すると spec と矛盾、または性能・複雑性のトレードオフが発生 | トレードオフを整理して AskUserQuestion |
| **誤指摘** | レビュアーの誤解や、既に対応済み | コメントで説明 |

### デフォルトは「修正」

迷ったら修正する。修正コストが低いものを議論するのは時間の無駄。

### spec 妥協が必要な場合

以下のフォーマットで AskUserQuestion する:

```
レビュー指摘: [指摘の要約]

選択肢:
A) [修正内容] — [メリット] / [デメリット (spec 変更、性能影響など)]
B) [代替案] — [メリット] / [デメリット]
C) [現状維持] — [理由]

推奨: [推奨案とその理由]
```

## 3. Resolve

修正をコミット & push したら、対応済みのレビュースレッドを resolve する。

```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "<THREAD_ID>"}) {
    thread { isResolved }
  }
}'
```

複数スレッドがある場合は mutation 内で `t1: resolveReviewThread(...)` `t2: resolveReviewThread(...)` のように一括 resolve する。

**resolve する前に必ず:**
- テストが pass していること (`go test ./...` / `npm test` 等)
- lint が pass していること
- push 済みであること

## 4. 全体フロー

```
PR 作成
  └→ CI watch (fail → fix → push → re-watch)
      └→ CI green
          └→ レビュー待ち
              └→ レビュー確認依頼
                  ├→ 即修正 → commit & push → resolve
                  ├→ spec トレードオフ → AskUser → 決定に従い修正 or spec 更新 → resolve
                  └→ 誤指摘 → コメントで説明 → resolve
                      └→ CI re-watch (fail → fix loop)
```
