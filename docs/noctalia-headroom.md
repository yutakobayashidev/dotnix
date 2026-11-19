# Headroomの利用枠表示

Noctaliaでは[個人fork版のHeadroom](https://github.com/yutakobayashidev/headroom)を使う。
`modules/features/window-manager/noctalia/default.nix` がコミットとソースハッシュを固定し、
Home Managerで `$XDG_DATA_HOME/noctalia/plugins/headroom` に配置する。
プラグインIDは `yutakobayashidev/headroom`、バーのIDは `yutakobayashidev/headroom:usage`。
community版の `ayagmar/headroom` は有効化リストから外している。

## Codex

`codex-auth list --api --json` から登録済みアカウントの利用枠を一括取得する。
バーの標準表示はcodex-authで選択中のアカウント、パネルは全アカウントを表示する。
バーにも複数表示する場合は、ウィジェット設定の `bar_accounts` を `all` にする。

アカウントの追加・削除・名前変更・認証更新はcodex-authで行う。
HeadroomにはCodexのアカウント管理UIを設けず、`CODEX_HOME` ごとのディレクトリも探索しない。
取得に失敗したアカウントはエラー表示となり、前回の成功値があればキャッシュとして残す。

## OpenCode Go

OpenCode 2でログインすると、保存済みOAuthセッションを使って5時間・週間・月間の利用枠を取得する。

```sh
opencode auth login opencode
```

認証元は `${XDG_DATA_HOME:-~/.local/share}/opencode/opencode.db` の有効な `opencode` セッション。
`OPENCODE_DB` を設定した場合はそのDBを読む。PythonヘルパーがDBを読み取り専用で開き、
`https://opencode.ai/console/api/go/status` に問い合わせる。
トークンをNix設定やHeadroomのキャッシュに保存せず、更新はOpenCodeに任せる。
ブラウザーCookieや別のAPIキー設定は使わない。未ログイン・期限切れの場合はログイン案内を表示する。

Noctaliaを有効にしたホストには、必要な `codex-auth` とPython 3も導入する。
Goの取得成功はログイン済み環境で確認する必要があり、未ログイン環境ではテストデータによる検証までとなる。

## 更新と確認

forkを更新するときはNixモジュールの `rev` と `hash` を更新する。
Noctaliaのcommunity更新では、この固定したforkは更新されない。
通常のシステム反映後に、次のコマンドで有効状態の確認と再取得ができる。

```sh
noctalia msg plugins list | rg 'yutakobayashidev/headroom'
noctalia msg plugin yutakobayashidev/headroom:poller all refresh
```
