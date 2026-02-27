# TODO

## agent-skills-nix: `pkgs.system` 廃止対応

- [ ] `Kyure-A/agent-skills-nix` に issue を立てる
  - `pkgs.system` が5箇所で使われており `evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'` が発生
  - 該当箇所:
    - `flake.nix:85` — `system = pkgs.system;`
    - `lib/default.nix:387` — `activeTargets = targetsFor { ... system = pkgs.system; };`
    - `lib/default.nix:523` — `system ? pkgs.system,`
    - `modules/home-manager/agent-skills.nix:15` — `system = pkgs.system;`
    - `modules/home-manager/agent-skills.nix:24` — `system = pkgs.system;`
  - 修正: `pkgs.system` → `pkgs.stdenv.hostPlatform.system`
- [ ] upstream 修正後、`nix flake update agent-skills` で取り込む

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
