## マージ（merge workflow）

人間がPRをレビューして承認し、ProjectのStatusを `Merging` に移した。この段階ではPRの内容を変えずに、default branchへsquash mergeする。コードの修正と衝突の解消はimplement workflowが担う。

1. PRの状態を確認する。openかつdraftでなければ手順2へ進む。既にmergedなら手順5へ進む。マージされずにclosedなら、理由を記録して `Blocked` にする。
2. `gh pr view PR --json mergeable,mergeStateStatus` でdefault branchとの関係を確認する。`UNKNOWN` なら数秒おいて取り直す。
   - `mergeable` が `CONFLICTING`: 衝突しているファイルをPRコメントへ記録して `Implement` に戻す。implementが解消し、verifyを経て `In review` に戻る。
   - `mergeStateStatus` が `BEHIND`（最新化が必須のブランチ保護）: `gh pr update-branch PR` でdefault branchを取り込む。PR自体の差分は変わらない。
3. `gh pr checks PR --watch --fail-fast` で全チェックの完了を待ち、必須チェックがあれば `gh pr checks PR --required` でも確認する。失敗・skip・cancelがあれば、根拠をPRコメントへ記録して `Implement` に戻す。チェックが0件なら `Blocked` にする。
4. チェックが通ったhead SHAを取得し、`gh pr merge PR --squash --match-head-commit <SHA>` でマージする。途中でheadが変わって失敗した場合は手順2からやり直す。
5. `gh pr view PR --json state` が `MERGED` であることを確認する。マージキューやauto-mergeに入っただけでMERGEDにならない場合は、その旨を記録して `Blocked` にする。MERGEDなら、対象Issueが閉じたことを確認し、ProjectのStatusを `Done` にする。

## 完了報告

Status更新（後述の「ProjectのStatus更新」）と記録が完了したら、結果にかかわらず `herdr-symphony report --status done --summary "結果: マージ済み|戻した先; PR: ...; head: ...; merge commit: ...; 理由: ..."` と報告する。ここでdoneはマージ作業の完了を示し、PRがマージされたことを意味しない。
