## ProjectのStatus更新

このworkflowのsuccess_stateは未設定なので、判定した状態は自分で更新する。対象はowner `yutakobayashidev` のProject `3`、project ID `PVT_kwHOBXG-b84BsTu0`、item ID `{{ issue.id }}`。

1. `gh project field-list 3 --owner yutakobayashidev --format json` でStatus field IDと、判定先のoption IDを取得する。IDを名前から確認し、他の項目を変更しない。
2. `gh project item-edit --id '{{ issue.id }}' --project-id PVT_kwHOBXG-b84BsTu0 --field-id FIELD_ID --single-select-option-id OPTION_ID` で判定先へ移す。
3. Projectを再取得し、対象itemのStatusが判定先になったことを確認する。

Projectの更新や結果記録が失敗した場合は `--status failed` で報告する。SymphonyがBlockedへ移す。処理中は必要に応じてpendingを報告する。
