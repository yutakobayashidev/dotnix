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
flake.nix              # エントリポイント（inputs: nixpkgs, home-manager, ghostty, llm-agents, gh-nippou）
├── nix/               # NixOS設定
│   ├── configuration.nix  # システム設定（Hyprland, fcitx5-mozc, Docker, nh）
│   └── home/              # home-manager設定
│       ├── default.nix    # ユーザーパッケージ・imports
│       └── programs/      # プログラム設定
│           ├── zsh.nix        # シェル設定（エイリアス、カスタム関数）
│           ├── hyprpanel.nix  # ステータスバー
│           ├── ghostty/       # ターミナル
│           ├── neovim.nix
│           ├── tmux.nix
│           ├── git.nix
│           └── vscode.nix
└── nvim/              # Neovim設定（Lua）
    └── lua/plugins/   # lazy.nvim プラグイン設定
```

## Key Aliases (zsh.nix)

- `rebuild` → `nh os switch`
- `g` → 引数なし: ghq+peco、引数あり: git
- `gh-q` → ghq + fzf でリポジトリ選択・clone
