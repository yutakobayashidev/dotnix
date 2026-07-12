# Codex Limit Auto Reset Service Design

## Goal

Run `ghcr.io/fa0311/codex-limit-auto-reset` continuously on `B450M-Pro4`
through the declarative NixOS OCI Containers module.

## Architecture

Add a focused service module at
`systems/nixos/services/codex-limit-auto-reset/default.nix` and import it from
`systems/nixos/B450M-Pro4/default.nix`. The module defines one
`virtualisation.oci-containers.containers.codex-limit-auto-reset` container and
uses the host's existing default Podman backend.

The container uses the upstream image without additional configuration. It
mounts `/home/yuta/.config/codex` at `/data/codex`, matching this repository's
`CODEX_HOME` configuration rather than upstream's default `~/.codex` path.

## Lifecycle and Failure Handling

The OCI Containers module starts the container at `multi-user.target` and
manages it as a systemd service. The generated unit restarts on failure. No
container-level restart option is added, avoiding overlapping Podman and
systemd restart policies.

Image download, authentication, or runtime failures remain visible through the
generated `podman-codex-limit-auto-reset.service` logs.

## Verification

- Evaluate the configured image and volume attributes for `B450M-Pro4`.
- Build the `B450M-Pro4` NixOS toplevel.
- Inspect the diff to confirm only the new service module and its host import
  are part of the implementation.

## Documentation Impact

The service does not change repository architecture, user-facing commands, or
agent instructions, so no README, AGENTS, CLAUDE, or additional docs update is
required beyond this design record.
