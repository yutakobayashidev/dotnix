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
