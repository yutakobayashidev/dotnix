# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# システム設定を反映（rebuild）
nh os switch
# または
sudo nixos-rebuild switch --flake .

# 特定のパッケージを検索
nix search nixpkgs <package>

# flake入力を更新
nix flake update
```

## Architecture

NixOS flake構成 with home-manager（nixos-unstable）

```
flake.nix                          # エントリポイント
├── nix/
│   ├── hosts/                     # ホスト固有の設定
│   │   └── nixos/
│   │       ├── default.nix        # システム基本設定（boot, network, locale）
│   │       └── hardware-configuration.nix
│   ├── profiles/                  # プロファイル定義
│   │   ├── cli-minimal.nix        # 最小CLI環境
│   │   ├── cli.nix                # CLI環境（docker, tailscale含む）
│   │   └── gui.nix                # GUI環境（niri, audio, bluetooth含む）
│   ├── modules/
│   │   ├── core/                  # システムモジュール
│   │   │   ├── default.nix
│   │   │   ├── packages.nix       # システムパッケージ（firefox, zsh, nh, nix-ld）
│   │   │   ├── user.nix           # ユーザー設定 + home-manager統合
│   │   │   ├── niri.nix           # Niri WM + greetd
│   │   │   ├── input.nix          # fcitx5 + hazkey
│   │   │   ├── audio.nix          # pipewire
│   │   │   ├── bluetooth.nix
│   │   │   ├── yubikey.nix        # YubiKey + PAM U2F
│   │   │   ├── docker.nix
│   │   │   ├── tailscale.nix
│   │   │   ├── android.nix
│   │   │   ├── fonts.nix
│   │   │   └── ssh.nix
│   │   ├── home/                  # home-manager設定
│   │   │   ├── default.nix
│   │   │   ├── packages.nix       # ユーザーパッケージ
│   │   │   ├── niri.nix           # Niri home設定
│   │   │   └── programs/          # プログラム設定
│   │   │       ├── zsh.nix
│   │   │       ├── ghostty/
│   │   │       ├── neovim.nix
│   │   │       ├── tmux.nix
│   │   │       ├── git.nix
│   │   │       ├── vscode.nix
│   │   │       ├── waybar.nix
│   │   │       └── ...
│   │   └── lib/                   # ヘルパー関数
│   │       └── helpers/
│   └── packages/                  # カスタムパッケージ
│       ├── polycat.nix
│       ├── git-wt-clean.nix
│       └── ...
└── nvim/                          # Neovim設定（Lua）
    └── lua/plugins/               # lazy.nvim プラグイン設定
```

## Key Features

- **WM**: Niri（スクロール可能なタイリングWM）
- **IME**: fcitx5 + hazkey（LLM変換）
- **YubiKey**: PAM U2F認証サポート（polkit, hyprlock対応）
- **Development**: Docker, Tailscale, Android開発環境

## Key Aliases

定義場所: `nix/modules/home/programs/zsh.nix`

- `rebuild` → `nh os switch`
- `g` → 引数なし: ghq+peco、引数あり: git
- `gh-q` → ghq + fzf でリポジトリ選択・clone
- `yolo` → `claude --dangerously-skip-permissions`
