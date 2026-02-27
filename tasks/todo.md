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
