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

NixOS desktops use swayidle to dim the display after 5 minutes and lock after
15 minutes. Automatic suspend after 30 minutes is opt-in through the Home Manager
option `my.services.swayidle.suspend.enable`; the `laptop` profile enables it by
default. Desktop machines, including UM790-Pro, stay awake for SSH and remote builds.
Hosts can override the laptop default by setting the option to `false`.

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
- **Launcher**: [Vicinae](https://github.com/vicinaehq/vicinae), including [AI Sessions](https://github.com/yutakobayashidev/vicinae-extension-ai-session) for Codex/Claude Code history search and resume; see [configuration and updates](vicinae.md)
- **Wallpaper**: Noctalia with per-host initial images set through `services.wallpaper.imagePath`; later selections are managed by Noctalia
- **IME**: fcitx5 + [hazkey](https://github.com/aster-void/nix-hazkey) (LLM-powered Japanese input)
- **Speech-to-text**: Handy with automatic startup and Niri shortcuts
- **Personal context**: OpenBrief context recall on the ThinkPad
- **AI development**: Codex Desktop for Linux, Claude Desktop, Grok Bot, Hermes Desktop, and Orca on graphical hosts; [Orca headless server](orca.md) on UM790-Pro
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
- **AI development**: Claude Desktop, Hermes Desktop, and Orca via the desktop profile
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

### OwnTracks collection on UM790-Pro

The Workspace endpoint `https://home.yutakobayashi.com/api/collect/owntracks` accepts HTTP-mode OwnTracks messages over the tailnet. The service initializer creates `~/.local/state/twitter-lite/owntracks/` (0700) and `owntracks-credentials.json` (0600) with a random password on first start; existing credentials survive rebuilds. Android needs Tailscale, HTTP mode, and the username/password from that file. Records are daily raw JSONL, separate from SQLite; back up this directory and the credential file privately.

The `ori-xiaomi-s200` Home Manager user service receives Xiaomi S200 measurements over Bluetooth and sends them to `/api/collect/xiaomi-scale`. Its executable and Python dependencies come from the Ori flake's `xiaomi-s200` package. Provision `~/.local/state/twitter-lite/xiaomi-s200/collector.json` and `ingest.json` privately with mode 0600; the former contains the BLE key, the latter binds measurements to the existing weight routine. Secrets are never Nix values. Back up both files, `outbox/` (SQLite retry queue), and `archive/` (immutable measurements). The collector starts only when its configuration exists. See Ori's `docs/xiaomi-s200-collector.md` for the JSON schemas and initial pairing procedure. When testing unpublished Ori changes, build with `--override-input twitter-lite git+file:///home/yuta/ghq/git.yutakobayashi.com/yuta/twitter-lite --no-write-lock-file`; update the pinned Ori input before a normal deployment without this override.

### Workspace Journal persistence

The web service sets `TWITTER_LITE_JOURNAL_DIR` to `~/.local/state/twitter-lite/journal` for persistent Journal entries. Entries append to `YYYY-MM-DD.md` files using Japan Standard Time (Asia/Tokyo), with timestamp headings. Corrections append another entry rather than rewriting existing content. Back up this directory alongside the SQLite database; database-only backups do not include Journal files. Rebuilds preserve the state directory.

### Workspace routine builder

The web service sets `TWITTER_LITE_ROUTINE_DIR` to `~/.local/state/twitter-lite/routines`. Back up `definitions.jsonl` (immutable form versions) and daily `YYYY-MM-DD.jsonl` execution records together. Creation and editing use the existing Codex runtime and its login with structured output; saved routines can execute without inference. The routine schedule controls Home display, not external notifications.

### Workspace TypeSafe credentials

`secrets/ori-typesafe.env` stores the Home composer TypeSafe API key encrypted with sops for UM790-Pro. Home Manager decrypts it as `ori-typesafe-env`; the web service reads that secret through `EnvironmentFile` after `sops-nix.service`. Edit it with `sops secrets/ori-typesafe.env`, keeping `TYPESAFE_API_KEY` as the dotenv variable, and rebuild. Recovery requires the UM790-Pro age key or a replacement API key. Never commit plaintext credentials.
