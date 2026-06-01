# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# システム設定を反映（NixOS / macOS 共通）
nix run .#switch

# ビルドのみ（適用なし）
nix run .#build

# 特定のパッケージを検索
nix search nixpkgs <package>

# flake入力を更新
nix flake update
```

## Agent Skills

このリポジトリは`agent-skills-nix`でスキルを管理しています。

AGENTS.mdには個別のスキル名やファイル構成を置かず、実設定と専用ドキュメントを正本とします。スキルを追加・変更した場合は、必要に応じてそちらを更新してください。

## Secret Handling

シークレット、APIトークン、sops/age秘密鍵、SSH秘密鍵を`/tmp`や`/private/tmp`などの一時ディレクトリに書かないでください。生成・編集が必要な場合は、最終配置先（例: `~/.config/sops/age/keys.txt`）か、repo外の永続ディレクトリに`chmod 600`で保存し、配置先と復旧手順を記録してください。

## Architecture

NixOS & macOS flake構成 with home-manager（nixos-unstable + nixpkgs-stable fallback）

Host 定義は root の `flake-module.nix` が `hosts` table から生成します。Host 固有の system 設定は `systems/<platform>/<hostname>/`、platform 共通の system 設定は `systems/<platform>/common.nix` や `systems/<platform>/desktop.nix`、Home Manager 設定は `homes/<platform>/<hostname>/` に置きます。アプリ単位の Home Manager 設定は direct import 用の `applications/`、option 付きの再利用可能な Home Manager 機能 module は `nix/modules/home/` に置きます。共通 module は `nix/modules/` に寄せ、NixOS profile は `nix/modules/profiles/nixos/`、Home Manager profile は `nix/modules/profiles/home/` に置きます。

独自パッケージの実体は `yutakobayashidev/nur-packages` で管理し、`dotnix` は GitHub flake input として取り込みます。ローカルの未 push 変更を試すときだけ `--override-input nur-packages path:../nur-packages` を使います。

## Key Features

### NixOS

- **WM**: Niri（スクロール可能なタイリングWM）
- **IME**: fcitx5 + hazkey（LLM変換）
- **YubiKey**: PAM U2F認証サポート（polkit, swaylock対応）
- **Development**: Docker, Tailscale, Android開発環境、UM790-ProのVirtualBox
- **Observability**: B450M-Pro4 の Grafana / Prometheus / Loki と Claude Code OTLP telemetry

### macOS

- **Homebrew**: GUI アプリ管理（Ghostty, Raycast, Chrome等）
- **Touch ID**: sudo認証対応
- **1Password**: Shell Plugins（gh, awscli2）

## Key Shell Shortcuts

定義場所: `zsh/config/aliases.zsh`, `zsh/functions/*.zsh`

- `rebuild` → `nix run .#switch`（NixOS / macOS 共通）
- `g` → 引数なし: ghq+fzf、引数あり: git
- `Ctrl+G` → `g` の引数なしと同じ ghq+fzf ピッカー
- `gh-q` → ghq + fzf でリポジトリ選択・clone
- `yolo` → `claude --dangerously-skip-permissions`
