# Noctaliaのカレンダー連携

カレンダー同期と予定の通知は、NoctaliaのHome Manager設定で有効にしている。
`nix run .#switch` で反映後、**Settings → Calendar → Accounts → Add Account** からアカウントを追加する。

Google Calendarは **Google** を選び、ローカルの識別名（例: `personal_google`）を入力して **Save and Connect** を押し、ブラウザーで認証する。CalDAV・iCloud・ICS・ローカルのvdirにも対応する。
アカウントはNoctaliaのGUIで管理し、Googleの更新トークンなどの認証情報はSecret Serviceに保存する。認証情報をNix設定に書かない。

同期した予定はControl CenterのCalendarタブに表示される。通知は予定側の指定を優先し、通知時刻の指定がない予定には原則10分前を使う。Google Calendarで明示的に通知を削除した予定は通知しない。
会議リンクのある予定やリマインダーをクリックすると、ブラウザーで参加リンクを開ける。

これはカレンダー表示・通知・参加リンクの機能であり、次の会議名をバーへ常時表示する設定は含まない。

仕様: [Noctalia Calendar](https://docs.noctalia.dev/noctalia/services/calendar/)
