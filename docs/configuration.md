# Configuration reference

## Hosts

| Machine                   | Name                       | Description                      | OS                     | System         | Stable |
| ------------------------- | -------------------------- | -------------------------------- | ---------------------- | -------------- | ------ |
| B450M Pro4                | B450M-Pro4                 | Self-hosted services and storage | NixOS                  | x86_64-linux   | ◎      |
| UM790 Pro                 | UM790-Pro                  | Dev mini PC and AI agent host    | NixOS                  | x86_64-linux   | ◎      |
| ThinkPad X1 Carbon Gen 13 | ThinkPad-X1-Carbon-Gen13   | Mobile development workstation   | NixOS                  | x86_64-linux   | ◎      |
| X870 Steel Legend WiFi    | X870-Steel-Legend-WiFi     | Gaming and GPU server            | NixOS                  | x86_64-linux   | △      |
| X870 Steel Legend WiFi    | X870-Steel-Legend-WiFi-WSL | Windows WSL dev environment      | NixOS (WSL)            | x86_64-linux   | ◎      |
| Pi 5                      | pi5                        | Headless Raspberry Pi 5          | NixOS                  | aarch64-linux  | △      |
| OCI Ampere A1 VM          | oci-a1                     | Remote ARM builder VM            | NixOS                  | aarch64-linux  | △      |
| M2 MacBook Air            | M2-MacBook-Air             | macOS laptop workstation         | macOS                  | aarch64-darwin | ◎      |
| Galaxy S23 FE             | Galaxy-S23FE               | Android nix-on-droid environment | Android (nix-on-droid) | aarch64-linux  | △      |

## Module structure

```
flake.nix                    # Flake inputs and entry point
flake-module.nix             # Host table and generated system outputs
├── systems/
│   ├── common.nix               # Shared system imports and activation hooks
│   ├── nixos/
│   │   ├── common.nix           # Shared NixOS host imports
│   │   ├── desktop.nix          # Shared NixOS desktop system settings
│   │   ├── laptop.nix           # Shared NixOS laptop system settings
│   │   ├── fonts.nix            # Shared NixOS font settings
│   │   ├── input-method.nix     # Shared NixOS input method settings
│   │   ├── services/            # Host/system service bundles (microVMs, secrets, etc.)
│   │   ├── installer/            # Custom x86_64 NixOS installer ISO
│   │   ├── B450M-Pro4/           # NixOS host config (services, disko, impermanence)
│   │   ├── UM790-Pro/           # NixOS host config (boot, network, locale)
│   │   ├── ThinkPad-X1-Carbon-Gen13/   # NixOS laptop host config
│   │   ├── X870-Steel-Legend-WiFi/   # NixOS desktop host config
│   │   ├── X870-Steel-Legend-WiFi-WSL/   # NixOS-WSL host config (WSL, locale)
│   │   ├── pi5/                 # NixOS host config (headless Pi 5)
│   │   └── oci-a1/              # OCI Ampere A1 NixOS host config (disko, boot, network)
│   ├── darwin/
│   │   ├── common.nix           # Shared macOS host imports
│   │   ├── desktop.nix          # Shared macOS desktop system settings
│   │   ├── homebrew.nix         # Shared macOS Homebrew app set
│   │   └── M2-MacBook-Air/      # macOS host config
│   └── android/
│       ├── common.nix           # Shared nix-on-droid configuration
│       └── Galaxy-S23FE/        # nix-on-droid host config
├── homes/
│   ├── common.nix               # Shared Home Manager glue
│   ├── nixos/                   # NixOS Home Manager host config
│   ├── darwin/                  # macOS Home Manager host config
│   └── android/                 # nix-on-droid home hook
├── modules/
│   ├── features/        # Application and system features grouped by purpose
│   ├── profiles/        # Typed profile bundles with optional system-to-home cascade
│   └── per-system/      # Packages, devshell, checks, and formatter configuration
├── lib/                 # Profile builder and shared evaluation helpers
├── overlays/            # Custom packages (overlay)
├── registry/                # Agent skill source manifests and lock file
└── zsh/                     # Zsh config
```

Application and system features live in purpose-based namespaces under `modules/features/`:

| Namespace          | Contents                                                                      |
| ------------------ | ----------------------------------------------------------------------------- |
| `browser/`         | Firefox and Chromium                                                          |
| `coding-agents/`   | Coding agents, agent skills, and MCP integration                              |
| `desktop/`         | Launcher, wallpaper, desktop search, and sleep prevention                     |
| `development/`     | API tools, scripting, and code analysis                                       |
| `editor/`          | Emacs, Neovim, and Zed                                                        |
| `input/`           | Input methods and speech-to-text                                              |
| `media/`           | Media capture, downloads, and music library tools                             |
| `network/`         | Tailscale and Cloudflare tunnels                                              |
| `nix/`             | Nix daemon, nixpkgs policy, and remote builds                                 |
| `observability/`   | Log shipping and rotation                                                     |
| `productivity/`    | Personal workflows, information retrieval, and document tools                 |
| `shell/`           | Zsh with Powerlevel10k and general command-line utilities                     |
| `system/`          | Boot, persistence, authentication, hardware, and home environment foundations |
| `terminal/`        | Terminal emulator and multiplexer                                             |
| `version-control/` | Git, GitHub CLI, Jujutsu, and repository tools                                |
| `window-manager/`  | Niri, status bar, idle handling, and screen lock                              |

Feature modules register through `flake.modules.{nixos,darwin,homeManager}` and are discovered automatically. Namespace directories have no `default.nix`; a directory with `default.nix` is one feature, so its helper files are not imported separately. Keep application assets alongside their feature. Shared CLI modules apply to every Home Manager host; desktop and host-specific apps are enabled with `my.programs.<name>.enable` (or `my.services.swayidle.enable`) in the corresponding home configuration or profile.

Home Manager deploys repository-backed configuration from the flake source in the Nix store. Initial activation does not require a checkout at the configured `ghq` path; clone the repository only when making or applying later changes.

## Shell prompt

Zsh uses Powerlevel10k with a transparent, two-line prompt and pastel colors.
`zsh/config/p10k.zsh` controls the OS, directory, and Git icons on the left;
the right shows failures, commands taking at least three seconds, background jobs,
active development environments, and the hostname (user@host for remote/root sessions). Node.js and Rust versions
appear only in matching projects. Oh My Zsh still supplies shell plugins, with its
theme disabled. Ghostty uses JetBrainsMono Nerd Font for the icons.

Edit the tracked prompt configuration instead of running `p10k configure`.
Apply with `nix run .#switch`, then open a new terminal. Empty prompt backgrounds
inherit Ghostty's existing opacity (92% on Linux and 75% on macOS).

## Desktop appearance

NixOS desktops use Catppuccin Mocha. `lib/desktop-palette.nix` supplies the Niri,
Ghostty, and swaylock colors matching Noctalia's built-in dark palette. The bar
keeps Vicinae, Cat, Codexbar, and now-playing media on the left, workspaces in the center, and essential
status indicators on the right. Long media titles scroll on hover; Codexbar labels
and tooltips convert Waybar markup to plain text. Media controls, CPU/RAM, microphone volume, and
brightness remain available in Control Center; its shortcuts include media and
wallpaper selection. The wallpaper picker browses `~/wallpapers`.

[Cat](https://github.com/noctalia-dev/community-plugins/tree/main/cat)
(`dotnetrob/cat`) is enabled declaratively through `programs.noctalia.settings.plugins.enabled`.
Noctalia fetches it from its built-in community source and manages its runtime
files and updates; its version is not pinned by Nix. Initial acquisition requires
network access. The custom Codexbar adapter remains locally deployed.
Cat follows the shell theme and animates using CPU usage from Noctalia's system
monitor: it sleeps below 15%, walks from 15%, and runs from 60% by default.
Clicking the cat opens its CPU panel. The default size is 24px, with no permanent
CPU percentage label.

Niri uses 12px gaps and rounded corners with a 2px focus ring. Linux Ghostty uses
92% background opacity; macOS keeps its existing settings. GTK 3 uses
adw-gtk3-dark with Papirus-Dark icons, while GTK 4 retains its native theme and
receives the dark color preference. The design rationale and reference settings
are in the [desktop style report](noctalia-style-report.md).

## Key features

### NixOS

- **WM**: [Niri](https://github.com/YaLTeR/niri) (scrollable tiling Wayland compositor)
- **Desktop shell**: [Noctalia](https://noctalia.dev/) with Catppuccin Mocha, a floating bar, centered workspaces, notifications, OSD, and control center
- **Launcher**: [Vicinae](https://github.com/vicinaehq/vicinae)
- **Wallpaper**: Noctalia with per-host initial images set through `services.wallpaper.imagePath`; later selections are managed by Noctalia
- **IME**: fcitx5 + [hazkey](https://github.com/aster-void/nix-hazkey) (LLM-powered Japanese input)
- **Speech-to-text**: Handy with automatic startup and Niri shortcuts
- **Personal context**: Screenpipe CLI/desktop app plus OpenBrief context recall on the ThinkPad
- **AI development**: Codex Desktop for Linux and Orca on graphical hosts
- **Audio production**: Bitwig Studio, native synths/effects, and Windows VST support via PipeWire JACK and yabridge
- **YubiKey**: PAM U2F authentication (polkit, swaylock)
- **Development**: Docker, Tailscale, Android development environment, VirtualBox on UM790-Pro
- **Pentesting**: GhidraMCP, Wireshark, OWASP ZAP, mitmproxy, and security analysis tools on the ThinkPad
- **Reddit CLI**: Every NixOS/macOS Home Manager host gets `rdt`, defaulting to `https://rdt.home.yutakobayashi.com`. Override with `RDT_GATEWAY_URL` or `--url`; for example, `rdt search "nixos flakes" --limit 5`. Apply the updated configuration on each machine with `nix run .#switch`.
- **Reddit**: rdt-gateway on B450M-Pro4 at `https://rdt.home.yutakobayashi.com`, with its stdio MCP server exposed through OpenAI Secure MCP Tunnel. Add the tunnel as a custom MCP server in ChatGPT; running the tunnel does not automatically install the plugin.
- **Remote MCP**: [Sandboxed local tools on UM790-Pro](local-mcp-tunnel.md) through an OpenAI Secure MCP Tunnel
- **Self-hosted services**: Nextcloud, Immich, Gitea, Home Assistant, linkding, n8n, WebHashtag, Grafana, Prometheus, Loki, Claude Code telemetry, Twitter API Safe Relay and rdt-gateway with Secure MCP Tunnel, Twitter Lite, and comin on B450M-Pro4
- **Personal Workspace (UM790-Pro)**: the `twitter-lite` Home Manager service serves the web app at `https://home.yutakobayashi.com` and HTTP MCP on port 3006, with a dedicated OpenAI Secure MCP Tunnel. The `twitter-lite-runtime` Elixir/OTP user service runs Codex for Board handoffs and Research through an authenticated loopback API on port 4318. It persists execution state under `twitter-lite/execution`; a generated `runtime-token` file is shared with the web app. Unfinished runs are interrupted on restart and resume only by explicit followup. The `twitter-lite-events` user service independently monitors Beeper through the `um790` CLI target and delivers queued MCP Events webhooks, sharing the app SQLite database and credential key.
- **Agent microVMs**: Hermes Agent on UM790-Pro (Slack and Discord) and OpenClaw on B450M-Pro4 via microvm.nix

### macOS

- **Homebrew**: GUI app management via casks (Ghostty, Chrome, OrbStack, etc.)
- **brew-nix**: Homebrew cask packages managed as Nix packages (version pinning & rollback)
- **Speech-to-text**: Handy with launchd automatic startup
- **Touch ID**: sudo authentication support
- **1Password**: Shell Plugins (gh, awscli2, tea)

## Managed tools

- **AI Development**: claude-code, codex, dsh (DeepSeek Harness), grok, opencode, pi, ccusage; Codex-enabled environments include [codex-transcribe](https://github.com/nakasyou/codex-transcribe) for audio transcription using the existing Codex login (`codex-transcribe recording.wav --language ja`)
- **Version Control**: git, lazygit, jujutsu (jj), git-lfs, git-wt
- **Core CLI**: ripgrep, fzf, jq, zoxide, lsd, btop, yazi, tmux
- **Communication**: Beeper Desktop and local MCP; Beeper CLI on UM790-Pro only; halloy (IRC)
- **Editors**: Neovim, VSCode
- **Terminal**: Ghostty, Zsh + Oh My Zsh
- **Network**: bandwhich, speedtest-cli, WireGuard
- **Pentesting**: Ghidra, Wireshark, OWASP ZAP, mitmproxy, nmap, codex-security, vulnix
