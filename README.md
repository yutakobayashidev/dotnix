# dotnix

Personal NixOS, macOS (nix-darwin), and Android (nix-on-droid) configurations,
with Home Manager for user environments.

## Usage

Run from the repository root on a configured host:

```sh
nix run .#switch              # Build and apply (NixOS / macOS)
nix run .#build               # Build without applying
nix run .#fmt                 # Format the repository
nix flake update             # Update flake inputs
nix run .#skills-sources-lock # Update agent skill sources separately
```

Review and commit skill source manifests and their lock file together.
For initial setup, see the [installation guides](docs/README.md#system-installation-guides).

## Layout

| Path                             | Purpose                                                |
| -------------------------------- | ------------------------------------------------------ |
| `flake.nix`, `flake-module.nix`  | Inputs, host definitions, and generated configurations |
| `systems/`                       | System and host settings                               |
| `homes/`                         | Home Manager settings by platform and host             |
| `modules/features/`              | Features grouped by purpose                            |
| `modules/profiles/`              | Feature bundles                                        |
| `modules/per-system/`            | Packages, development shells, and checks               |
| `lib/`, `overlays/`, `registry/` | Shared helpers, package overlays, and skill sources    |

## Documentation

- [All guides](docs/README.md)
- [Hosts and module architecture](docs/configuration.md)
- [Remote builds](docs/remote-build.md)
- [Agent skills](docs/agent-skills.md)
- [Hermes Quantified Self wiki share](docs/hermes-qs-wiki.md)
- [Firefox](docs/firefox.md)
- [Network topology](docs/README.md#network-topology)

Project templates live in [ashiba](https://github.com/yutakobayashidev/ashiba).
See also [DeepWiki](https://deepwiki.com/yutakobayashidev/dotnix).
