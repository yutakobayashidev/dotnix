---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
---

# Cargo Registry ソースの読み取り許可

Rustの依存クレートのソースコードを調査する際、`~/.cargo/registry/src/` 配下のファイルを読み取ってよい。

ライブラリの内部実装の確認、デバッグ、API の挙動調査などに活用すること。
