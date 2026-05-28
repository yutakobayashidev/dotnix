# dotnix

[![DeepWiki](https://img.shields.io/badge/DeepWiki-yutakobayashidev%2Fdotnix-blue.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAyCAYAAAAnWDnqAAAAAXNSR0IArs4c6QAAA05JREFUaEPtmUtyEzEQhtWTQyQLHNak2AB7ZnyXZMEjXMGeK/AIi+QuHrMnbChYY7MIh8g01fJoopFb0uhhEqqcbWTp06/uv1saEDv4O3n3dV60RfP947Mm9/SQc0ICFQgzfc4CYZoTPAswgSJCCUJUnAAoRHOAUOcATwbmVLWdGoH//PB8mnKqScAhsD0kYP3j/Yt5LPQe2KvcXmGvRHcDnpxfL2zOYJ1mFwrryWTz0advv1Ut4CJgf5uhDuDj5eUcAUoahrdY/56ebRWeraTjMt/00Sh3UDtjgHtQNHwcRGOC98BJEAEymycmYcWwOprTgcB6VZ5JK5TAJ+fXGLBm3FDAmn6oPPjR4rKCAoJCal2eAiQp2x0vxTPB3ALO2CRkwmDy5WohzBDwSEFKRwPbknEggCPB/imwrycgxX2NzoMCHhPkDwqYMr9tRcP5qNrMZHkVnOjRMWwLCcr8ohBVb1OMjxLwGCvjTikrsBOiA6fNyCrm8V1rP93iVPpwaE+gO0SsWmPiXB+jikdf6SizrT5qKasx5j8ABbHpFTx+vFXp9EnYQmLx02h1QTTrl6eDqxLnGjporxl3NL3agEvXdT0WmEost648sQOYAeJS9Q7bfUVoMGnjo4AZdUMQku50McDcMWcBPvr0SzbTAFDfvJqwLzgxwATnCgnp4wDl6Aa+Ax283gghmj+vj7feE2KBBRMW3FzOpLOADl0Isb5587h/U4gGvkt5v60Z1VLG8BhYjbzRwyQZemwAd6cCR5/XFWLYZRIMpX39AR0tjaGGiGzLVyhse5C9RKC6ai42ppWPKiBagOvaYk8lO7DajerabOZP46Lby5wKjw1HCRx7p9sVMOWGzb/vA1hwiWc6jm3MvQDTogQkiqIhJV0nBQBTU+3okKCFDy9WwferkHjtxib7t3xIUQtHxnIwtx4mpg26/HfwVNVDb4oI9RHmx5WGelRVlrtiw43zboCLaxv46AZeB3IlTkwouebTr1y2NjSpHz68WNFjHvupy3q8TFn3Hos2IAk4Ju5dCo8B3wP7VPr/FGaKiG+T+v+TQqIrOqMTL1VdWV1DdmcbO8KXBz6esmYWYKPwDL5b5FA1a0hwapHiom0r/cKaoqr+27/XcrS5UwSMbQAAAABJRU5ErkJggg==)](https://deepwiki.com/yutakobayashidev/dotnix)

## Target

| Machine                | Name                   | OS                     | System         | Stable |
| ---------------------- | ---------------------- | ---------------------- | -------------- | ------ |
| B450M Pro4             | B450M-Pro4             | NixOS                  | x86_64-linux   | ◎      |
| UM790 Pro              | UM790-Pro              | NixOS                  | x86_64-linux   | ◎      |
| X870 Stell Legend WiFi | X870-Stell-Legend-WiFi | NixOS (WSL)            | x86_64-linux   | ◎      |
| Pi 5                   | pi5                    | NixOS                  | aarch64-linux  | △      |
| M2 MacBook Air         | M2-MacBook-Air         | macOS                  | aarch64-darwin | ◎      |
| Galaxy S23 FE          | Galaxy-S23FE           | Android (nix-on-droid) | aarch64-linux  | △      |

## Module Structure

```
flake.nix                    # Entry point and host table
flake-module.nix             # Generates nixos/darwin/nix-on-droid outputs from hosts
├── systems/
│   ├── common.nix               # Shared system imports and activation hooks
│   ├── nixos/
│   │   ├── common.nix           # Shared NixOS host imports
│   │   ├── desktop.nix          # Shared NixOS desktop system settings
│   │   ├── fonts.nix            # Shared NixOS font settings
│   │   ├── input-method.nix     # Shared NixOS input method settings
│   │   ├── services/            # Host/system service bundles (microVMs, secrets, etc.)
│   │   ├── B450M-Pro4/           # NixOS host config (services, disko, impermanence)
│   │   ├── UM790-Pro/           # NixOS host config (boot, network, locale)
│   │   ├── X870-Stell-Legend-WiFi/   # NixOS-WSL host config (WSL, locale)
│   │   └── pi5/                 # NixOS host config (headless Pi 5)
│   ├── darwin/
│   │   ├── common.nix           # Shared macOS host imports
│   │   ├── desktop.nix          # Shared macOS desktop system settings
│   │   ├── homebrew.nix         # Shared macOS Homebrew app set
│   │   └── M2-MacBook-Air/      # macOS host config
│   └── android/
│       └── Galaxy-S23FE/        # nix-on-droid host config
├── homes/
│   ├── common.nix               # Shared Home Manager glue
│   ├── nixos/                   # NixOS Home Manager host config
│   ├── darwin/                  # macOS Home Manager host config
│   └── android/                 # nix-on-droid home hook
├── applications/                # Directly imported Home Manager app configs (git, tmux, browsers, niri, misc)
├── nix/
│   ├── modules/
│   │   ├── profiles/
│   │   │   ├── nixos/       # NixOS profiles (cli, cli-server, gui, laptop)
│   │   │   └── home/        # Home Manager profiles (base, terminal, cli, development, desktop)
│   │   ├── nixos/           # Reusable optioned NixOS modules (docker, tailscale, security, kubo)
│   │   ├── darwin/          # Reusable optioned nix-darwin modules
│   │   ├── shared/          # Shared system modules across platforms (nix, nixpkgs)
│   │   ├── nix-on-droid/    # nix-on-droid shared modules
│   │   └── home/            # Home Manager shared modules and optioned feature modules
│   └── overlays/            # Custom packages (overlay)
├── agents/skills/           # Claude Code agent skills
├── nvim/                    # Neovim config (Lua)
└── zsh/                     # Zsh config
```

## Documentation

### System Installation Guides

- [docs/systems/B450M-Pro4.md](docs/systems/B450M-Pro4.md) - NixOS installation guide
- [docs/systems/B450M-Pro4-HDD-service-storage.md](docs/systems/B450M-Pro4-HDD-service-storage.md) - B450M-Pro4 HDD service storage setup
- [docs/systems/UM790Pro.md](docs/systems/UM790Pro.md) - NixOS installation guide
- [docs/systems/X870-Stell-Legend-WiFi.md](docs/systems/X870-Stell-Legend-WiFi.md) - NixOS-WSL installation guide
- [docs/systems/Pi5.md](docs/systems/Pi5.md) - NixOS installation guide for Raspberry Pi 5
- [docs/systems/M2-MacBook-Air.md](docs/systems/M2-MacBook-Air.md) - nix-darwin installation guide for macOS
- [docs/systems/Galaxy-S23FE.md](docs/systems/Galaxy-S23FE.md) - nix-on-droid installation guide for Android
- [docs/systems/Ventoy-NixOS-Minimal.md](docs/systems/Ventoy-NixOS-Minimal.md) - Ventoy USB for NixOS installation

### Other

- [docs/music-workflow.md](docs/music-workflow.md) - CD ripping and music library management

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
- `nix run .#fmt` - Format configured file types (Nix, Lua, shell, TOML, Python, etc.) via [treefmt](https://github.com/numtide/treefmt-nix)

### macOS

- `nix run .#switch` - Build and apply nix-darwin + Home Manager configuration (`sudo darwin-rebuild switch`)
- `nix run .#build` - Build configuration without applying
- `nix run .#fmt` - Format configured file types (Nix, Lua, shell, TOML, Python, etc.) via [treefmt](https://github.com/numtide/treefmt-nix)

Both use [nix-output-monitor](https://github.com/maralorn/nix-output-monitor) for build output.

## Key Features

### NixOS

- **WM**: [Niri](https://github.com/YaLTeR/niri) (scrollable tiling Wayland compositor)
- **IME**: fcitx5 + [hazkey](https://github.com/aster-void/nix-hazkey) (LLM-powered Japanese input)
- **YubiKey**: PAM U2F authentication (polkit, swaylock)
- **Development**: Docker, Tailscale, Android development environment, VirtualBox on UM790-Pro
- **Self-hosted services**: Nextcloud, Immich, Gitea, Home Assistant, ArchiveBox, n8n, Grafana, Prometheus, Loki, Claude Code telemetry, and comin on B450M-Pro4
- **Agent microVMs**: Hermes Agent on UM790-Pro and OpenClaw on B450M-Pro4 via microvm.nix

### macOS

- **Homebrew**: GUI app management via casks (Ghostty, Chrome, OrbStack, etc.)
- **brew-nix**: Homebrew cask packages managed as Nix packages (version pinning & rollback)
- **Touch ID**: sudo authentication support
- **1Password**: Shell Plugins (gh, awscli2)

## Managed Tools

- **AI Development**: claude-code, codex, grok, opencode, ccusage, vibe-kanban
- **Version Control**: git, lazygit, jujutsu (jj), git-lfs, git-wt
- **Core CLI**: ripgrep, fzf, jq, zoxide, lsd, btop, yazi, tmux
- **Communication**: halloy (IRC)
- **Editors**: Neovim, VSCode
- **Terminal**: Ghostty, Zsh + Oh My Zsh
- **Network**: nmap, bandwhich, speedtest-cli

## Agent Skills

Agent skills are managed via [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix).

- **Config**: `nix/modules/home/coding-agents/agent-skills`
- **Local skills**: `agents/skills/`
- **External skills**: [anthropics/skills](https://github.com/anthropics/skills), [vercel-labs/skills](https://github.com/vercel-labs/skills), [ast-grep/claude-skill](https://github.com/ast-grep/claude-skill), [mattpocock/skills](https://github.com/mattpocock/skills), [obra/superpowers](https://github.com/obra/superpowers)
- **Deploy targets**: `~/.agents/skills`, `~/.config/claude/skills`, `~/.config/codex/skills`, Hermes microVM `/var/lib/hermes/.hermes/skills`, OpenClaw microVM `/persist/openclaw/.openclaw/workspace/skills`

Avoid maintaining a fixed skill list here. Treat `agents/skills/` and `nix/modules/home/coding-agents/agent-skills` as the source of truth.

## Templates

Project templates are managed in [ashiba](https://github.com/yutakobayashidev/ashiba). See the repository for available templates.
