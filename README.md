# dotnix

[![DeepWiki](https://img.shields.io/badge/DeepWiki-yutakobayashidev%2Fdotnix-blue.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAyCAYAAAAnWDnqAAAAAXNSR0IArs4c6QAAA05JREFUaEPtmUtyEzEQhtWTQyQLHNak2AB7ZnyXZMEjXMGeK/AIi+QuHrMnbChYY7MIh8g01fJoopFb0uhhEqqcbWTp06/uv1saEDv4O3n3dV60RfP947Mm9/SQc0ICFQgzfc4CYZoTPAswgSJCCUJUnAAoRHOAUOcATwbmVLWdGoH//PB8mnKqScAhsD0kYP3j/Yt5LPQe2KvcXmGvRHcDnpxfL2zOYJ1mFwrryWTz0advv1Ut4CJgf5uhDuDj5eUcAUoahrdY/56ebRWeraTjMt/00Sh3UDtjgHtQNHwcRGOC98BJEAEymycmYcWwOprTgcB6VZ5JK5TAJ+fXGLBm3FDAmn6oPPjR4rKCAoJCal2eAiQp2x0vxTPB3ALO2CRkwmDy5WohzBDwSEFKRwPbknEggCPB/imwrycgxX2NzoMCHhPkDwqYMr9tRcP5qNrMZHkVnOjRMWwLCcr8ohBVb1OMjxLwGCvjTikrsBOiA6fNyCrm8V1rP93iVPpwaE+gO0SsWmPiXB+jikdf6SizrT5qKasx5j8ABbHpFTx+vFXp9EnYQmLx02h1QTTrl6eDqxLnGjporxl3NL3agEvXdT0WmEost648sQOYAeJS9Q7bfUVoMGnjo4AZdUMQku50McDcMWcBPvr0SzbTAFDfvJqwLzgxwATnCgnp4wDl6Aa+Ax283gghmj+vj7feE2KBBRMW3FzOpLOADl0Isb5587h/U4gGvkt5v60Z1VLG8BhYjbzRwyQZemwAd6cCR5/XFWLYZRIMpX39AR0tjaGGiGzLVyhse5C9RKC6ai42ppWPKiBagOvaYk8lO7DajerabOZP46Lby5wKjw1HCRx7p9sVMOWGzb/vA1hwiWc6jm3MvQDTogQkiqIhJV0nBQBTU+3okKCFDy9WwferkHjtxib7t3xIUQtHxnIwtx4mpg26/HfwVNVDb4oI9RHmx5WGelRVlrtiw43zboCLaxv46AZeB3IlTkwouebTr1y2NjSpHz68WNFjHvupy3q8TFn3Hos2IAk4Ju5dCo8B3wP7VPr/FGaKiG+T+v+TQqIrOqMTL1VdWV1DdmcbO8KXBz6esmYWYKPwDL5b5FA1a0hwapHiom0r/cKaoqr+27/XcrS5UwSMbQAAAABJRU5ErkJggg==)](https://deepwiki.com/yutakobayashidev/dotnix)

## Target

| Machine | Name | OS | System | Stable |
|---|---|---|---|---|
| UM790 Pro | UM790-Pro | NixOS | x86_64-linux | ◎ |
| Still Legend x870 | Still-Legend-x870 | NixOS (WSL) | x86_64-linux | △ |
| M2 MacBook Air | M2-MacBook-Air | macOS | aarch64-darwin | ◎ |
| Galaxy S23 FE | Galaxy-S23FE | Android (nix-on-droid) | aarch64-linux | △ |


## Module Structure

```
flake.nix                    # Entry point (nixos + darwin + nixOnDroid Configurations)
├── nix/
│   ├── hosts/
│   │   ├── UM790-Pro/           # NixOS host config (boot, network, locale)
│   │   ├── Still-Legend-x870/   # NixOS-WSL host config (WSL, locale)
│   │   ├── M2-MacBook-Air/      # macOS host config
│   │   └── Galaxy-S23FE/        # nix-on-droid host config
│   ├── profiles/
│   │   ├── cli-minimal.nix  # Minimal CLI environment
│   │   ├── cli.nix          # CLI environment (docker, tailscale)
│   │   ├── cli-server.nix   # Server CLI environment (docker, no tailscale)
│   │   ├── gui.nix          # GUI environment (niri, audio, bluetooth)
│   │   ├── laptop.nix       # Laptop environment (gui + extras)
│   │   └── darwin.nix       # macOS environment
│   ├── modules/
│   │   ├── linux/           # NixOS system modules (niri, docker, audio, etc.)
│   │   ├── darwin/          # macOS nix-darwin modules (homebrew, system defaults, nix)
│   │   ├── nix-on-droid/    # nix-on-droid shared modules
│   │   └── home/            # Home Manager shared modules (zsh, git, claude-code)
│   └── overlays/            # Custom packages (overlay)
├── agents/skills/           # Claude Code agent skills
├── nvim/                    # Neovim config (Lua)
└── zsh/                     # Zsh config
```

## Documentation

- [docs/UM790Pro.md](docs/UM790Pro.md) - NixOS installation guide
- [docs/Still-Legend-x870.md](docs/Still-Legend-x870.md) - NixOS-WSL installation guide
- [docs/M2-MacBook-Air.md](docs/M2-MacBook-Air.md) - nix-darwin installation guide for macOS
- [docs/Galaxy-S23FE.md](docs/Galaxy-S23FE.md) - nix-on-droid installation guide for Android

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

- **Homebrew**: GUI app management via casks (Ghostty, Chrome, OrbStack, etc.)
- **brew-nix**: Homebrew cask packages managed as Nix packages (version pinning & rollback)
- **Touch ID**: sudo authentication support
- **1Password**: Shell Plugins (gh, awscli2)

## Managed Tools

- **AI Development**: claude-code, codex, opencode, ccusage, vibe-kanban
- **Version Control**: git, lazygit, jujutsu (jj), git-lfs, git-wt
- **Core CLI**: ripgrep, fzf, jq, zoxide, lsd, btop, yazi, tmux
- **Communication**: halloy (IRC)
- **Editors**: Neovim, VSCode
- **Terminal**: Ghostty, Zsh + Oh My Zsh
- **Development**: Node.js, Bun, MoonBit, Google Cloud SDK, Typst
- **Network**: nmap, bandwhich, speedtest-cli

## Agent Skills

Claude Code skills are managed via [agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix).

- **Config**: `nix/modules/home/agent-skills.nix`
- **Local skills**: `agents/skills/`
- **External skills**: [anthropics/skills](https://github.com/anthropics/skills), [vercel-labs/skills](https://github.com/vercel-labs/skills), [ast-grep/claude-skill](https://github.com/ast-grep/claude-skill)
- **Deploy targets**: `~/.agents/skills`, `~/.config/claude/skills`, `~/.config/codex/skills`

Key skills: `social-digest`, `oura-daily-watch`, `gha-lint`, `check-similarity`, `dce` (local), `docx`, `pdf`, `pptx`, `xlsx`, `frontend-design`, `webapp-testing`, `skill-creator` (Anthropic), `find-skills` (Vercel), `ast-grep` (ast-grep), `ui-ux-pro-max` (community)

