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

Skills are managed using `agent-skills-nix`. Skill-only repositories, including `yutakobayashidev/skills`, are declared in `registry/sources/*.nix` and pinned in `registry/sources.lock.json`. Shared source loading lives in `lib/skill-sources.nix`; package-providing repositories remain flake inputs.

When adding a new skill to `yutakobayashidev/skills`, prefer scanning with a GitHub URL to find existing skill implementations:

```bash
OPENAI_BASE_URL=https://litellm.home.yutakobayashi.com OPENAI_API_KEY=sk-proxy skillspector scan https://github.com/<user>/<repo>
OPENAI_BASE_URL=https://litellm.home.yutakobayashi.com OPENAI_API_KEY=sk-proxy skillspector scan https://github.com/<user>/<repo>/tree/main/path/to/skill
```

Update skill sources from the repository root:

```bash
nix run .#skills-sources-lock
```

Review and commit both manifests and the generated lock file. `nix flake update` does not update these skill sources. See [skill source maintenance](docs/agent-skills.md) for testing local changes before pushing.

Do not list individual skill names here — the source of truth is the skill selection modules and the skills repo documentation.

## Secret Handling

Do not write secrets, API tokens, sops/age private keys, or SSH private keys to temporary directories like `/tmp` or `/private/tmp`. If generation or editing is needed, save to the final destination (e.g. `~/.config/sops/age/keys.txt`) or a persistent directory outside the repo with `chmod 600`, and record the location and recovery procedure.

## Architecture

NixOS & macOS flake configuration with home-manager (nixos-unstable + nixpkgs-stable fallback).

Host definitions are generated from the `hosts` table in the root `flake-module.nix`. Host-specific system config goes in `systems/<platform>/<hostname>/`, platform-shared concrete system config in `systems/<platform>/common.nix`, `desktop.nix`, or `laptop.nix`. Home Manager config goes in `homes/<platform>/<hostname>/`; concrete platform desktop configuration remains in `homes/<platform>/desktop.nix`. Application and system features live in purpose-grouped namespaces under `modules/features/`; see the namespace table in [docs/configuration.md](docs/configuration.md). Feature modules register themselves through `flake.modules.{nixos,darwin,homeManager}` and are injected into every matching configuration. Shared CLI modules are unconditional; desktop and host-specific applications expose `my.programs.<name>.enable` or `my.services.<name>.enable`, set by the corresponding home configuration or profile. Keep imported upstream modules outside conditional config blocks. Profiles live in `modules/profiles/`, use `lib/mkProfile.nix`, and may span system and Home Manager scopes; profiles with a Home Manager half cascade their system toggle into overridable home feature defaults. Since every child of `modules/` is now a flake-parts module, the registry layer is flat like the reference repository.

Place new features in an existing purpose namespace when possible. Namespace directories must not have `default.nix`: `lib/collectFlakeModules.nix` recurses into them, while a directory with `default.nix` is imported as one feature with its supporting assets. When moving a feature, update path references in host configs, tests, formatter exclusions, `.sops.yaml`, and docs, and verify that module discovery is unchanged apart from the new paths.

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
- **Speech-to-text**: Handy with automatic startup and Niri shortcuts
- **Personal context**: Screenpipe CLI/desktop app plus OpenBrief context recall on the ThinkPad
- **AI development**: Codex Desktop for Linux and Orca on graphical hosts
- **Audio production**: Bitwig Studio, native synths/effects, and Windows VST support via PipeWire JACK and yabridge
- **YubiKey**: PAM U2F authentication support (polkit, swaylock)
- **Development**: Docker, Tailscale, Android dev environment, and VirtualBox on UM790-Pro
- **Remote builds**: B450M-Pro4 and ThinkPad offload to UM790-Pro over Tailscale; see [rollout and offline build commands](docs/remote-build.md)
- **Pentesting**: [CTF and security analysis toolkit](docs/ctf-tools.md), including [GhidraMCP](docs/ghidra-mcp.md), on the ThinkPad
- **Observability**: Grafana / Prometheus / Loki on B450M-Pro4, Claude Code OTLP telemetry

### macOS

- **Homebrew**: GUI app management (Ghostty, Raycast, Chrome, etc.)
- **AI development**: Orca via the desktop profile
- **Speech-to-text**: Handy with launchd automatic startup
- **Touch ID**: sudo authentication
- **1Password**: Shell Plugins (gh, awscli2, tea)

## Key Shell Shortcuts

Defined in: `zsh/config/aliases.zsh`, `zsh/functions/*.zsh`

- `rebuild` → `nix run .#switch` (NixOS / macOS)
- `g` → no args: ghq+fzf, with args: git
- `Ctrl+G` → same as `g` with no args (ghq+fzf picker)
- `gh-q` → ghq + fzf repo selection / clone
- `yolo` → `claude --dangerously-skip-permissions`
