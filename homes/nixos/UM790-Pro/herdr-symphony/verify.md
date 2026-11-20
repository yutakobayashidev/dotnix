## 検証・差し戻し

この段階は実装を変更せず、PRの最新headに対して独立したコードレビューと検証を行う。既存のAIレビューがあってもdiffと要件を自分で照合する。外部のレビューbotを新たに呼び出す必要はない。

1. PRのhead SHAを取得し、作業ツリーがその版と一致することを確認する。Issueの要件、diff、テスト、最新の全レビュー指摘を照合する。具体的な不具合・不足と根拠のファイル位置を記録する。
2. リポジトリで必要とされる検証を実行する。UI変更はPRの動画/GIFが最新の変更を示し、表示・再生できることを確認する。添付メディアに個人情報（実在の氏名・連絡先・アカウント・トークン・実データの内容）が写っていないことも確認する。実機確認が必須なら実機の証跡を確認し、エミュレーションで代用したと断定しない。
3. `gh pr checks PR --required` と `gh pr checks PR` で必須CIと全チェックを確認する。進行中なら `gh pr checks PR --required --watch --fail-fast` などで待つ。チェック0件、必須CIが設定されていない、取得失敗、必須チェックのskip/cancelは合格にしない。取得できない・時間内に完了しない場合はBlockedにする。
4. 結論を出す直前にPRのhead SHAとレビューを再取得する。途中でheadが変わったら新しい版を検証し直す。

## 判定

- 合格: 要件・ローカル検証・必須CI・コードレビュー・必要な視覚検証を満たし、対応すべき指摘が残っていない → `In review`。
- 修正可能な不具合、CI失敗、未対応のレビュー指摘がある → 根拠と修正条件をPRコメントへ記録して `Implement`。
- 認証不足、CIガード未設定、実機や人間の判断が必要、既存PRがmerged/closed → 理由を記録して `Blocked`。
- 添付済みのメディアに個人情報が写っている → アップロード済みファイルの削除は人間がGitHub Supportへ依頼する必要があるため、該当ファイルのURLを記録して `Blocked`。個人情報そのものは記録に書き写さない。
- Agent Logsで同じ未解決事項が直近2回の検証から進展していなければ、自動で差し戻し続けず `Blocked`。今回が3回目の同じ失敗になる場合に適用する。

## Projectの更新と完了報告

このworkflowのsuccess_stateは未設定なので、判定した状態は自分で更新する。対象はowner `yutakobayashidev` のProject `3`、project ID `PVT_kwHOBXG-b84BsTu0`、item ID `{{ issue.id }}`。

1. `gh project field-list 3 --owner yutakobayashidev --format json` でStatus field IDと、判定先のoption IDを取得する。IDを名前から確認し、他の項目を変更しない。
2. `gh project item-edit --id '{{ issue.id }}' --project-id PVT_kwHOBXG-b84BsTu0 --field-id FIELD_ID --single-select-option-id OPTION_ID` で判定先へ移す。
3. Projectを再取得し、対象itemのStatusが判定先になったことを確認する。
4. 検証判定・状態更新・根拠の記録が完了したら、合否にかかわらず `herdr-symphony report --status done --summary "判定: ...; head: ...; 根拠: ...; 未解決: ..."` と報告する。ここでdoneは検証作業の完了を示し、PRの合格やマージを意味しない。

Projectの更新や結果記録が失敗した場合は `--status failed` で報告する。SymphonyがBlockedへ移す。処理中は必要に応じてpendingを報告する。
