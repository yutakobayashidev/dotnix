# TODO

## agent-skills-nix: `pkgs.system` 廃止対応

- [x] `Kyure-A/agent-skills-nix` に issue を立てる → https://github.com/Kyure-A/agent-skills-nix/issues/23
- [x] PR を送る → https://github.com/Kyure-A/agent-skills-nix/pull/24 (draft)
  - 4ファイル7箇所: `pkgs.system` → `pkgs.stdenv.hostPlatform.system`
- [ ] PR マージ後、`nix flake update agent-skills` で取り込む

## sops-nix: WiFi秘密情報のセットアップ

- [ ] age public key を取得
  ```bash
  nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
  ```
  → `.sops.yaml` のプレースホルダーを置換
- [ ] secrets を暗号化
  ```bash
  nix-shell -p sops --run 'sops secrets/secrets.yaml'
  ```
  → `wifi_env` の `WIFI_PSK_HOME` を実際のパスワードに、SSID も `networking.nix` で設定
- [ ] 適用
  ```bash
  nix run .#switch
  ```

## cmux を brew-nix 管理に追加（macOS）

- [x] `brewCasks` で `cmux` 可否を確認する
- [x] `nix/modules/darwin/homebrew.nix` に `manaflow-ai/cmux` tap を追加する
- [x] `nix/modules/darwin/homebrew.nix` に `cmux` cask を追加する
- [x] `nix eval` で `homebrew.taps` / `homebrew.casks` への反映を確認する

### Review

- [x] `cmux` が宣言的にインストールされる構成になっていることを確認
- `pkgs.brewCasks` には `cmux` が存在しないため、`nix-darwin` の `homebrew` 宣言（tap + cask）で管理
- 検証結果: `homebrew.taps` に `manaflow-ai/cmux`、`homebrew.casks` に `cmux` が含まれることを確認

## cmux + difit 連携コマンドを追加

- [x] gist を参照して `zsh/functions` への実装方針を決める
- [x] `zsh/functions/difit-cmux.zsh` を追加する
- [x] `zsh/functions/README.md` に使い方を追記する
- [x] `zsh -n` で構文チェックを実行する

### Review

- [x] `cmux sidebar-state` の `focused_cwd` を起点に、対象 repo の差分を `difit` で起動する関数を追加
- [x] `origin/HEAD`（fallback: `origin/main`/`origin/master`）との分岐判定で diff 範囲を自動選択
- [x] 未追跡ファイルは `git add -N` で差分表示対象に含める
- [ ] 実行時の挙動確認（手元の `cmux` セッション上で `difit-cmux` 実行）

## Raycast から `difit-cmux` を起動できるようにする

- [x] `raycast/difit-cmux.sh` を追加する
- [x] スクリプトに実行権限を付与する
- [x] `bash -n` で構文チェックする

### Review

- [x] Raycast Script Command から `/bin/zsh -lic 'difit-cmux'` を実行する構成を追加
- [ ] Raycast 側で Script Commands path / hotkey 設定を行って実機確認
