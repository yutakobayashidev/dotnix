# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Apply system configuration (NixOS / macOS)
nix run .#switch

# Build only (no apply)
nix run .#build

# Search for a package
nix search nixpkgs <package>

# Update flake inputs
nix flake update
```

## Agent Skills

Skills are managed via the `skills` flake input (`yutakobayashidev/skills`) using `agent-skills-nix`.

When adding a new skill to `yutakobayashidev/skills`, prefer scanning with a GitHub URL to find existing skill implementations:

```bash
OPENAI_BASE_URL=https://litellm.home.yutakobayashi.com OPENAI_API_KEY=sk-proxy skillspector scan https://github.com/<user>/<repo>
OPENAI_BASE_URL=https://litellm.home.yutakobayashi.com OPENAI_API_KEY=sk-proxy skillspector scan https://github.com/<user>/<repo>/tree/main/path/to/skill
```

To test local changes before pushing:

```bash
nix run .#switch --override-input skills path:../skills
```

Do not list individual skill names or file layout here — the source of truth is the skills repo configuration and its documentation.

## Secret Handling

Do not write secrets, API tokens, sops/age private keys, or SSH private keys to temporary directories like `/tmp` or `/private/tmp`. If generation or editing is needed, save to the final destination (e.g. `~/.config/sops/age/keys.txt`) or a persistent directory outside the repo with `chmod 600`, and record the location and recovery procedure.

## Architecture

NixOS & macOS flake configuration with home-manager (nixos-unstable + nixpkgs-stable fallback).

Host definitions are generated from the `hosts` table in the root `flake-module.nix`. Host-specific system config goes in `systems/<platform>/<hostname>/`, platform-shared concrete system config in `systems/<platform>/common.nix`, `desktop.nix`, or `laptop.nix`. Home Manager config goes in `homes/<platform>/<hostname>/`; concrete platform desktop configuration remains in `homes/<platform>/desktop.nix`. Per-application Home Manager config uses direct-import `applications/`. Opt-in features live in `modules/features/`, register themselves through `flake.modules.{nixos,darwin,homeManager}`, and are injected into every matching configuration. Profiles live in `modules/profiles/`, use `lib/mkProfile.nix`, and may span system and Home Manager scopes; profiles with a Home Manager half cascade their system toggle into overridable home feature defaults. Since every child of `modules/` is now a flake-parts module, the registry layer is flat like the reference repository.

Custom packages are maintained in `yutakobayashidev/nur-packages` and pulled into `dotnix` as a GitHub flake input. To test local un-pushed changes, use:

```bash
nix run .#switch --override-input nur-packages path:../nur-packages
```

## Key Features

### NixOS

- **WM**: Niri (scrollable tiling WM)
- **Launcher**: Vicinae
- **Wallpaper**: swaybg via a Home Manager feature module
- **IME**: fcitx5 + hazkey (LLM-based conversion)
- **Personal context**: Screenpipe CLI and desktop app, built from source through the personal NUR
- **Audio production**: Bitwig Studio, native synths/effects, and Windows VST support via PipeWire JACK and yabridge
- **YubiKey**: PAM U2F authentication support (polkit, swaylock)
- **Development**: Docker, Tailscale, Android dev environment, VirtualBox on UM790-Pro, and [GhidraMCP integration](docs/ghidra-mcp.md)
- **Observability**: Grafana / Prometheus / Loki on B450M-Pro4, Claude Code OTLP telemetry

### macOS

- **Homebrew**: GUI app management (Ghostty, Raycast, Chrome, etc.)
- **Touch ID**: sudo authentication
- **1Password**: Shell Plugins (gh, awscli2)

## Key Shell Shortcuts

Defined in: `zsh/config/aliases.zsh`, `zsh/functions/*.zsh`

- `rebuild` → `nix run .#switch` (NixOS / macOS)
- `g` → no args: ghq+fzf, with args: git
- `Ctrl+G` → same as `g` with no args (ghq+fzf picker)
- `gh-q` → ghq + fzf repo selection / clone
- `yolo` → `claude --dangerously-skip-permissions`
