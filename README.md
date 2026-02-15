# dotnix

My NixOS configuration with Flakes and Home Manager.

## Stack

- **OS**: NixOS (unstable)
- **WM**: Niri（スクロール可能なタイリングWM）
- **Terminal**: Ghostty
- **Shell**: Zsh + Oh My Zsh
- **Editor**: Neovim, VSCode
- **IME**: fcitx5 + hazkey（LLM変換）

## Usage

```bash
# Apply configuration
nh os switch

# Or without nh
sudo nixos-rebuild switch --flake .

# Update flake inputs
nix flake update
```

## Structure

```
flake.nix                    # Flake entry point
└── nix/
    ├── hosts/nixos/         # Host-specific config (boot, network, locale)
    ├── profiles/            # Profile definitions (cli, gui, etc.)
    │   ├── cli-minimal.nix
    │   ├── cli.nix
    │   └── gui.nix
    ├── modules/
    │   ├── core/            # System modules (niri, docker, audio, etc.)
    │   └── home/            # Home Manager modules
    │       ├── packages.nix
    │       └── programs/    # Program configurations
    │           ├── zsh.nix
    │           ├── ghostty/
    │           ├── neovim.nix
    │           ├── git.nix
    │           └── ...
    └── packages/            # Custom packages (polycat, git-wt-clean, etc.)
```

## YubiKey Setup

YubiKeyでpolkit認証（1Passwordのロック解除など）を行うための設定。

### 1. YubiKeyの登録

```bash
mkdir -p ~/.config/Yubico
pamu2fcfg -o pam://nixos -i pam://nixos > ~/.config/Yubico/u2f_keys
```

### 2. 動作確認

```bash
pamtester polkit-1 yuta authenticate
```

YubiKeyをタッチして「successfully authenticated」と表示されればOK。

### 3. 1Password設定

1Password → 設定 → セキュリティ → 「システム認証でロック解除」を有効化
