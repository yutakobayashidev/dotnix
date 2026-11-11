# Noctaliaのカレンダー連携

カレンダー同期と予定の通知は、NoctaliaのHome Manager設定で有効にしている。
`nix run .#switch` で反映後、**Settings → Calendar → Accounts → Add Account** からアカウントを追加する。

Google Calendarは **Google** を選び、ローカルの識別名（例: `personal_google`）を入力して **Save and Connect** を押し、ブラウザーで認証する。CalDAV・iCloud・ICS・ローカルのvdirにも対応する。
アカウントはNoctaliaのGUIで管理し、Googleの更新トークンなどの認証情報はSecret Serviceに保存する。認証情報をNix設定に書かない。

同期した予定はControl CenterのCalendarタブに表示される。通知は予定側の指定を優先し、通知時刻の指定がない予定には原則10分前を使う。Google Calendarで明示的に通知を削除した予定は通知しない。
会議リンクのある予定やリマインダーをクリックすると、ブラウザーで参加リンクを開ける。

## Meeting Bar

[community版の Meeting Bar](https://github.com/noctalia-dev/community-plugins/tree/main/meeting-bar)
（`yuta/meeting-bar`）を `programs.noctalia.settings.plugins.enabled` で宣言的に有効化している。
取得と更新にはNoctalia標準のcommunityソースを使う。
Noctalia v5.4.0以降の同期済み予定を使うため、追加のGoogle認証は必要ない。

- バーには現在または次の予定名と残り時間を表示する。左クリックで日別の予定一覧、右クリックで現在または次の認識済みオンライン会議へ参加する。中クリックで設定を開く。
- 一覧では検索、カレンダー名による絞り込み、会議リンクのコピー、お気に入りの登録・削除ができる。リンクのない予定も日時と場所を表示する。
- Google Meet、Zoom、Teams、Webex、Jitsiなど認識済みのサービスには **Join**、それ以外のHTTP(S)リンクには **Open link** と表示する。
- **New meeting** は設定したURLを開く。初期値はGoogle Meetの作成ページであり、予定の作成や招待送信を自動実行するものではない。
- Niriでは `Mod+Shift+M` で一覧、`Mod+Ctrl+M` で現在または次のオンライン会議へ参加できる。キー設定は `nix run .#switch` で反映する。

**Settings → Plugins → Meeting Barの歯車** から、表示日数（初期値2日）、終日・終了済み予定の表示、対象カレンダー名、重複除去、現在の会議を優先するか、バーの表示内容と表示開始時刻を設定できる。
プレビュー時間が0なら、一覧の対象期間内にある次の予定を表示する。空のときも初期設定ではカレンダーアイコンを残す。

起動先を指定する場合、**Browser executable** には実行ファイル名または絶対パスを設定する。引数付きのシェルコマンドは指定しない。
**Executables by service** は `meet`、`zoom`、`teams`、`webex`、`jitsi` などをキーとして、サービスごとに起動先を上書きする。
どちらもHTTP(S) URLを1引数として渡す。ネイティブアプリ独自のURIへの変換は行わない。

## 全画面リマインダー

認識済みオンライン会議の開始5分前に、フォーカス中の画面を覆って会議名・日時と **Join meeting / Snooze 1 min / Dismiss** を表示する。
**Full-screen meeting reminders** でオン・オフ、通知までの時間とスヌーズ時間を変更できる。
標準通知は引き続きNoctalia本体が担当する。全画面表示は独立した機能であり、標準通知のDNDや予定ごとの通知指定には連動しない。

スヌーズはその予定だけを延期する。他の会議は延期しない。参加またはDismiss後は同じ回の会議を再表示しない。
表示済み情報、スヌーズ時刻、通知待ちの予定を保存し、サービス再起動後も引き継ぐ。他のリマインダーを表示中に通知時刻を迎えた会議は、画面を閉じた後に順番に表示する。開始から1分を超えて初めて取得した会議への遅延通知は出さないが、スヌーズした会議と通知待ちの会議は終了まで表示の対象になる。
予定が同期から消えた場合、終了した場合、終日予定へ変更された場合、認識済み会議リンクがなくなった場合は全画面表示を閉じる。終了・取消済みのスヌーズ記録と通知待ち記録は削除する。予定の取得と判定は15秒間隔で行う。

全画面表示はボタンで閉じる。Noctalia v5.4.0のlayer APIにはEscapeキーの独自コールバックがないため、CLIから閉じる場合は次を使う。

```sh
noctalia msg plugin yuta/meeting-bar:calendar all dismiss
noctalia msg plugin yuta/meeting-bar:calendar all snooze
```

## 保存場所と制限

プラグインのコードとテストはupstreamで管理する。dotnixにはローカルコピーを置かない。
プラグインIDは移行前と同じため、バー配置・ショートカット・保存済み設定を引き継ぐ。
お気に入りの会議名・URLとリマインダー情報は `noctalia.pluginDataDir()` が返すユーザー専用ディレクトリにJSONで保存する。
通常は `~/.local/state/noctalia/plugins/data/yuta/meeting-bar/` で、Noctaliaの状態ディレクトリ指定に従う。予定一覧全体や認証情報はプラグイン側では保存しない。

予定APIには出欠回答・参加者・説明文・安定したカレンダーID・予定詳細URLがない。辞退した予定の除外や参加者へのメールは実装していない。
カレンダー選択は名前によるため、別アカウントの同名カレンダーは区別できない。
未知の会議サービスは一般リンクとして開けるが、自動的な会議選択と全画面リマインダーの対象にはしない。
Niriではブラウザーを開いても前面に出ない場合がある。Noctalia側の同期に失敗しているときは、APIが返すキャッシュの予定が表示される。

## ローカル版からの移行と確認

`nix run .#switch` でHome Managerのローカル配布設定を削除する。
以前に開発用のpathソースを登録していた場合は、communityを更新してから削除する。
ローカルコピーや追加のpathソースは、標準のcommunityソースより優先される。

```sh
noctalia msg plugins update community
noctalia msg plugins source remove dotnix-meeting-bar
noctalia msg plugins enable yuta/meeting-bar
noctalia msg plugins enable yuta/codexbar-usage
noctalia msg plugins list | rg 'yuta/meeting-bar'
```

開発用ソースの削除時には、そのソースで検出されていたプラグインの有効状態も外れるため、
Meeting BarとローカルのCodex barを再度有効にする。Nix側の `plugins.enabled` にも両方を指定している。
一覧で `yuta/meeting-bar [community] ... enabled` と表示されることを確認する。
新規環境では開発用ソースの削除は不要。

仕様: [Noctalia Calendar](https://docs.noctalia.dev/noctalia/services/calendar/)
