# Codex Limit Auto Reset Service Design

## Goal

Run `codex-limit-auto-reset` continuously as a native systemd service on
`B450M-Pro4`.

## Architecture

Package the application in `yutakobayashidev/nur-packages` and export its
reusable NixOS module as `nixosModules.codex-limit-auto-reset`. Import that
module from `systems/nixos/B450M-Pro4/default.nix` and enable
`services.codex-limit-auto-reset`.

The service runs as `yuta` and sets `CODEX_HOME` to
`/home/yuta/.config/codex`, so Codex can refresh the existing ChatGPT
authentication directly. The Nix package supplies Node.js, the built
application, its dependencies, and the Codex CLI without a container runtime.

## Lifecycle and Failure Handling

The NixOS module starts `codex-limit-auto-reset.service` at
`multi-user.target`, after `network-online.target`, and restarts it on failure.

Authentication or runtime failures remain visible through
`codex-limit-auto-reset.service` logs.

## Verification

- Build the package from the local `nur-packages` checkout.
- Evaluate the generated systemd unit for `B450M-Pro4` with the local
  `nur-packages` input override.
- Build the configured package and generated systemd unit.
- Inspect the diff to confirm the OCI container definition was removed.

## Documentation Impact

The migration changes this service's deployment architecture, so this design
record is updated. It does not change repository-wide commands or agent
instructions, so README, AGENTS, and CLAUDE need no changes.
