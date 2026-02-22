# dotnix

NixOS & macOS (nix-darwin) configuration with Flakes and Home Manager.

## Module Structure

```
flake.nix                    # Entry point (nixosConfigurations + darwinConfigurations)
├── nix/
│   ├── hosts/
│   │   ├── nixos/           # NixOS host config (boot, network, locale)
│   │   └── darwin/          # macOS host config
│   ├── profiles/
│   │   ├── cli-minimal.nix  # Minimal CLI environment
│   │   ├── cli.nix          # CLI environment (docker, tailscale)
│   │   ├── gui.nix          # GUI environment (niri, audio, bluetooth)
│   │   └── darwin.nix       # macOS environment
│   ├── modules/
│   │   ├── linux/           # NixOS system modules (niri, docker, audio, etc.)
│   │   ├── darwin/          # macOS nix-darwin modules (homebrew, system defaults)
│   │   └── home/            # Home Manager shared modules (zsh, git, claude-code)
│   └── overlays/            # Custom packages (overlay)
├── agents/skills/           # Claude Code agent skills
├── nvim/                    # Neovim config (Lua)
└── zsh/                     # Zsh config
```

## Initial Setup

### NixOS

1. Install NixOS with the unstable channel

2. Clone this repository:

   ```sh
   git clone https://github.com/yutakobayashidev/dotnix.git ~/ghq/github.com/yutakobayashidev/dotnix
   cd ~/ghq/github.com/yutakobayashidev/dotnix
   ```

3. Apply the NixOS configuration:

   ```sh
   sudo nixos-rebuild switch --flake .#nixos
   ```

### macOS

1. Install [Nix](https://github.com/NixOS/nix-installer):

   ```sh
   curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
   ```

2. Clone this repository:

   ```sh
   git clone https://github.com/yutakobayashidev/dotnix.git ~/ghq/github.com/yutakobayashidev/dotnix
   cd ~/ghq/github.com/yutakobayashidev/dotnix
   ```

3. Apply the nix-darwin configuration (this will also install Homebrew automatically):

   ```sh
   sudo nix run nix-darwin -- switch --flake .#darwin
   ```

4. Reload your shell:

   ```sh
   exec zsh
   ```

## Daily Usage

```sh
# Apply changes (NixOS or macOS)
nix run .#switch

# Build without applying
nix run .#build

# Format all files (nix, lua, sh)
nix run .#fmt

# Update flake inputs
nix flake update
```

## Available Nix Apps

### NixOS

- `nix run .#switch` - Build and apply NixOS + Home Manager configuration (`sudo nixos-rebuild switch`)
- `nix run .#build` - Build configuration without applying
- `nix run .#fmt` - Format all files (nix, lua, sh) via [treefmt](https://github.com/numtide/treefmt-nix)

### macOS

- `nix run .#switch` - Build and apply nix-darwin + Home Manager configuration (`darwin-rebuild switch`)
- `nix run .#build` - Build configuration without applying
- `nix run .#fmt` - Format all files (nix, lua, sh) via [treefmt](https://github.com/numtide/treefmt-nix)

Both use [nix-output-monitor](https://github.com/maralorn/nix-output-monitor) for build output.

## Key Features

### NixOS

- **WM**: [Niri](https://github.com/YaLTeR/niri) (scrollable tiling Wayland compositor)
- **IME**: fcitx5 + [hazkey](https://github.com/aster-void/nix-hazkey) (LLM-powered Japanese input)
- **YubiKey**: PAM U2F authentication (polkit, swaylock)
- **Development**: Docker, Tailscale, Android development environment

### macOS

- **Homebrew**: GUI app management via casks (Ghostty, Raycast, Chrome, etc.)
- **brew-nix**: Homebrew cask packages managed as Nix packages (version pinning & rollback)
- **Touch ID**: sudo authentication support
- **1Password**: Shell Plugins (gh, awscli2)

## Managed Tools

- **AI Development**: claude-code, codex, opencode, ccusage, vibe-kanban
- **Version Control**: git, lazygit, jujutsu (jj), git-lfs, git-wt
- **Core CLI**: ripgrep, fzf, jq, zoxide, lsd, btop, yazi, starship, tmux
- **Editors**: Neovim, VSCode
- **Terminal**: Ghostty, Zsh + Oh My Zsh
- **Development**: Node.js, Bun, MoonBit, Google Cloud SDK, Typst
- **Network**: nmap, bandwhich, speedtest-cli

## Agent Skills

Claude Code skills are managed via [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix).

- **Config**: `nix/modules/home/agent-skills.nix`
- **Local skills**: `agents/skills/`
- **External skills**: [anthropics/skills](https://github.com/anthropics/skills), [vercel-labs/skills](https://github.com/vercel-labs/skills)
- **Deploy targets**: `~/.agents/skills`, `~/.config/claude/skills`

Key skills: `social-digest`, `oura-daily-watch` (local), `docx`, `pdf`, `pptx`, `xlsx` (Anthropic), `frontend-design`, `webapp-testing` (Anthropic), `find-skills` (Vercel), `ui-ux-pro-max` (community)

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
