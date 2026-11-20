## 視覚検証

Webフロントエンド、またはAndroidアプリの見た目・操作・画面遷移を変更する場合は、次の視覚的な検証も完了条件に含めてください。画面に影響しない変更では、この検証と添付は不要です。

### 撮影の基本

1. 変更した操作が分かる短い動画（MP4/WebM）またはGIFを撮り、必要に応じて静止画の変更前後比較も添えてください。新規画面は変更後のPreviewとして示してください。
2. 比較できる既存画面では、同じ条件（viewportまたはAVD、データ、テーマ、操作）で変更前後を記録してください。変更前の版が必要なら別worktreeを使い、進行中の変更を巻き戻さないでください。
3. 静止画は読み込みとアニメーションの完了を待ってから撮ってください。変更箇所が小さい場合は、画面全体に加えて該当部分を切り出した画像も添えてください。
4. メディアは `captures/` に保存し、コミットせずにPRへの添付で共有してください。撮影後はすべて開いて、対象の画面と変更点が写っていることを確認してください。真っ黒な画像や読み込み途中の画像は撮り直してください。GitHubに添付できるのは画像が10MBまで、動画が無料プランで10MBまでなので、超える場合はffmpegで解像度やビットレートを下げてください。

### Webの撮影

1. 撮影にはagent-browserを使い、開始前に `agent-browser skills get core` と `agent-browser record --help` を読んでインストール済みバージョンの操作方法を確認してください。
2. ブラウザセッション名にはIssue識別子のスラッシュと#をアンダースコアに置き換えた名前を使い、他の作業と分離してください。対象画面を開き、変更した操作と期待する表示を実際に確認してください。
3. 録画にはagent-browserのrecord機能を使ってください。Playwright MCPが利用可能な場合は追加の動作確認に使えます。

### Androidの撮影

1. 撮影はプロジェクトの開発用AVD（エミュレータ）で行い、AGENTS.mdとREADMEの手順に従って画面なし（`-no-window`）で起動してください。実機はIssueが実機での確認を求めている場合だけ使います。このホストに実機が接続されていなければ、視覚検証を未完了として報告してください。
2. 撮影前にSystemUIのデモモードでステータスバーを固定してください。時刻・電池・通知アイコンが変更前後で揃い、通知の内容も写りません。撮影後は `-e command exit` を送って解除してください。

   ```bash
   adb -s SERIAL shell settings put global sysui_demo_allowed 1
   adb -s SERIAL shell am broadcast -a com.android.systemui.demo -e command enter
   adb -s SERIAL shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 1200
   adb -s SERIAL shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
   adb -s SERIAL shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
   ```

3. 静止画はAndroid CLIの `android screen capture --device=SERIAL --output=captures/NAME.png` で撮ってください。`android-dev` を使うプロジェクトでは `android-dev android screen capture` として実行します。`--annotate` を付けると要素番号の枠が画像に描き込まれるので、PRに添付する画像では付けないでください。
4. 動画は、変更した画面までの操作をMaestroのFlowに書き、`maestro record --local FLOW.yaml` で作ってください。アプリの画面とFlowの実行内容を並べた動画になります。古い版のMaestroは `--local` を付けないと録画とFlowの出力をmobile.devのサーバーへ送るので、必ず付けてください。失敗した場合はFlowの `startRecording`/`stopRecording` か `adb shell screenrecord` を使ってください。`screenrecord` の既定のビットレートは20Mbpsなので、`--bit-rate 4000000` 程度に下げてください。Maestroは版によって出力先と使えるオプション（`--test-output-dir`、`cropOn` など）が違います。`maestro --version` とヘルプで確認し、出力を `captures/` へコピーしてください。

### 個人情報の確認とマスク

GitHubへアップロードしたファイルは、PR本文からリンクを消してもファイル自体が残ります。公開リポジトリでは、URLを知る人なら誰でも閲覧できます。次の確認はアップロード前に終えてください。

1. 撮影にはテスト用アカウントと架空のデータを使い、エミュレータやブラウザに個人のアカウントでログインしないでください。
2. 画像はすべて開いて確認してください。動画は1秒ごとのフレームを書き出して確認してください（例: `ffmpeg -i IN.mp4 -vf fps=1 captures/frames/%03d.png`）。確認する対象は次のとおりです。
   - 人物: 実在の氏名、メールアドレス、電話番号、住所、顔写真やアバター
   - アカウントと認証: アカウントID、トークン、APIキー、ワンタイムパスワード
   - 実データ: メッセージ、予定、通知、位置情報
   - 環境: URLのクエリ、ホスト名、IPアドレス、ユーザー名を含むパス
3. 写っていた場合は、テストデータで撮り直してください。撮り直せない静止画に限り、該当範囲を余白込みで不透明な単色の矩形で塗りつぶしてください（例: `magick IN.png -fill black -draw "rectangle X0,Y0 X1,Y1" OUT.png`）。ぼかしやモザイクは復元される場合があるので使わないでください。塗りつぶした画像は別ファイルとして保存し、元の画像はアップロードしないでください。動画は塗りつぶさずに撮り直してください。
4. マスク後の画像を開き、塗り残しがないことを確認してください。
5. 個人情報を含むファイルを誤ってアップロードした場合は、本文の修正だけで済ませず、そのURLを報告に含めて人間に知らせてください。ファイルの削除にはGitHub Supportへの依頼が必要です。

### PRへの添付と確認

1. PR作成後、既存のPR本文を読み、変更内容を証明するメディアを本文へ添付してください。この環境では `gh pr edit <PR> --attach <file>` を使えます。複数ファイルは `--attach` を繰り返します。本文を整える場合は `--body-file` を使い、既存の説明を保持してください。比較表示の整形には、利用可能ならbefore-and-afterスキルを読んで使用してください。
2. 更新後のPR本文を取得し、添付がGitHub上のURLになっていること、ローカルパスが残っていないことを確認してください。ブラウザでPRを開き、動画またはGIFが表示・再生できることも確認してください。PRには確認した画面・操作・結果を記載してください。
3. 起動・認証・録画・アップロードのいずれかが失敗した場合は、失敗箇所と再現手順をPRに記載し、視覚的な検証を未完了として報告してください。撮影や添付を実施していない状態を完了扱いにしないでください。
