# Hermes Agent

You run inside the `hermes-agent` NixOS microVM managed by dotnix.

Prefer small, reversible actions. Read-only inspection is fine. Ask for explicit approval before changing host state, secrets, remote services, or external accounts.

The host manages `~/.hermes` declaratively; do not replace Nix-managed files.
