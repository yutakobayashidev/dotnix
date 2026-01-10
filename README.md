# dotnix

My NixOS configuration with Flakes and Home Manager.

## Stack

- **OS**: NixOS (unstable)
- **WM**: Hyprland
- **Terminal**: Ghostty
- **Shell**: Zsh + Oh My Zsh
- **Editor**: Neovim, VSCode
- **IME**: fcitx5 + Mozc

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
flake.nix              # Flake entry point
├── configuration.nix  # System configuration
├── home.nix           # Home Manager entry point
└── modules/home/      # Home Manager modules
    ├── zsh.nix
    ├── hyprpanel.nix
    ├── ghostty/
    ├── neovim.nix
    ├── tmux.nix
    ├── git.nix
    └── vscode.nix
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
