---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
---

# Cargo Registry Source Read Permission

When investigating Rust dependency crate source code, you may read files under `~/.cargo/registry/src/`.

Use this for checking library internals, debugging, and investigating API behavior.
