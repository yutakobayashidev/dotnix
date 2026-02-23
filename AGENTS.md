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

- **設定**: `nix/modules/home/agent-skills.nix`
- **ローカルスキル**: `agents/skills/`
- **外部スキル**: `anthropics/skills`, `vercel-labs/skills`
- **デプロイ先**: `~/.agents/skills`, `~/.config/claude/skills`

主なスキル：
- `social-digest` - Discord + Mastodon投稿をObsidianに保存（ローカル）
- `oura-daily-watch` - Oura Ring データ + Discord行動分析（ローカル）
- `check-similarity` - TypeScript/JavaScript重複コード検知（ローカル）
- `dce` - Dead Code Elimination（ローカル）
- `docx`, `pdf`, `pptx`, `xlsx` - ドキュメント処理（Anthropic）
- `frontend-design`, `skill-creator`, `webapp-testing` - 開発支援（Anthropic）
- `find-skills` - スキル検索・発見支援（Vercel）
- `ui-ux-pro-max` - UI/UXデザインシステム生成（コミュニティ）
- `obsidian-markdown`, `obsidian-bases`, `json-canvas`, `obsidian-cli`, `defuddle` - Obsidian連携（kepano）

詳細: `agents/README.md`

## Architecture

NixOS & macOS flake構成 with home-manager（nixos-unstable）

```
flake.nix                          # エントリポイント
├── agents/
│   └── skills/                    # Claude Codeスキル
├── raycast/                       # macOS Raycastスクリプト
├── nix/
│   ├── hosts/                     # ホスト固有の設定
│   │   ├── nixos/                 # NixOS (x86_64-linux)
│   │   │   ├── default.nix        # システム基本設定（boot, network, locale）
│   │   │   └── hardware-configuration.nix
│   │   └── M2-MacBook-Air/        # macOS (aarch64-darwin)
│   │       └── default.nix        # ホスト名設定
│   ├── profiles/                  # プロファイル定義
│   │   ├── cli-minimal.nix        # 最小CLI環境
│   │   ├── cli.nix                # CLI環境（docker, tailscale含む）
│   │   ├── gui.nix                # GUI環境（niri, audio, bluetooth含む）
│   │   └── darwin.nix             # macOS環境
│   ├── modules/
│   │   ├── linux/                 # NixOS/Linuxシステムモジュール
│   │   │   ├── default.nix
│   │   │   ├── packages.nix       # システムパッケージ（firefox, zsh, nix-ld）
│   │   │   ├── nix.nix            # Nix設定
│   │   │   ├── user.nix           # ユーザー設定 + home-manager統合
│   │   │   ├── home-packages.nix  # Linux固有ユーザーパッケージ
│   │   │   ├── niri.nix           # Niri WM + greetd
│   │   │   ├── input.nix          # fcitx5 + hazkey
│   │   │   ├── audio.nix          # pipewire
│   │   │   ├── bluetooth.nix
│   │   │   ├── pam.nix            # PAM/polkit設定（YubiKey, U2F認証）
│   │   │   ├── docker.nix
│   │   │   ├── tailscale.nix
│   │   │   ├── android.nix
│   │   │   ├── fonts.nix
│   │   │   ├── ssh.nix
│   │   │   └── programs/          # Linux固有home-managerプログラム
│   │   │       ├── niri.nix       # Niri home設定
│   │   │       ├── waybar.nix
│   │   │       ├── swayidle.nix
│   │   │       └── swaylock.nix
│   │   ├── darwin/                # macOS nix-darwinモジュール
│   │   │   ├── default.nix
│   │   │   ├── system.nix         # macOS defaults (Dock, Finder, trackpad等)
│   │   │   ├── homebrew.nix       # Homebrew cask管理
│   │   │   ├── fonts.nix          # macOSフォント設定
│   │   │   ├── nix.nix            # Nix設定
│   │   │   └── packages.nix       # macOS固有ユーザーパッケージ（brew-nix含む）
│   │   ├── home/                  # home-manager共通設定
│   │   │   ├── default.nix        # 共通設定（zsh, git, claude-code等）
│   │   │   ├── packages.nix       # 共通ユーザーパッケージ
│   │   │   └── programs/          # 共通プログラム設定
│   │   │       ├── common-cli.nix # 共通CLIプログラム集約
│   │   │       ├── zsh.nix
│   │   │       ├── ghostty/
│   │   │       ├── neovim.nix
│   │   │       ├── tmux/
│   │   │       ├── git.nix
│   │   │       ├── gh.nix
│   │   │       ├── jj.nix
│   │   │       ├── claude-code.nix
│   │   │       ├── bat.nix
│   │   │       ├── btop.nix
│   │   │       └── fastfetch/
│   │   └── lib/                   # ヘルパー関数
│   │       └── helpers/
│   └── overlays/                  # カスタムパッケージ（overlay形式）
│       ├── default.nix            # 全overlayの集約
│       ├── polycat.nix
│       ├── aqua.nix
│       ├── similarity-ts.nix
│       ├── pretty-ts-errors-markdown.nix
│       └── ...
└── nvim/                          # Neovim設定（Lua）
    └── lua/plugins/               # lazy.nvim プラグイン設定
```

## Key Features

### NixOS
- **WM**: Niri（スクロール可能なタイリングWM）
- **IME**: fcitx5 + hazkey（LLM変換）
- **YubiKey**: PAM U2F認証サポート（polkit, swaylock対応）
- **Development**: Docker, Tailscale, Android開発環境

### macOS
- **Homebrew**: GUI アプリ管理（Ghostty, Raycast, Chrome等）
- **Touch ID**: sudo認証対応
- **1Password**: Shell Plugins（gh, awscli2）

## Key Aliases

定義場所: `zsh/config/aliases.zsh`

- `rebuild` → `nix run .#switch`（NixOS / macOS 共通）
- `g` → 引数なし: ghq+peco、引数あり: git
- `gh-q` → ghq + fzf でリポジトリ選択・clone
- `yolo` → `claude --dangerously-skip-permissions`
