# Session Context

## User Prompts

### Prompt 1

Implement the following plan:

# tunnelto overlay 追加

## Context
nixpkgsに tunnelto パッケージが存在しないため、既存の overlay パターンに従ってカスタムオーバーレイを作成する。

## 変更内容

### 1. `nix/overlays/tunnelto.nix` を作成
- `rustPlatform.buildRustPackage` を使用
- workspace構成のため `buildAndTestSubdir = "tunnelto"` を指定（クライアントバイナリのみ）
- rustls ベースなので openssl 等の native dependen...

### Prompt 2

コミットして

