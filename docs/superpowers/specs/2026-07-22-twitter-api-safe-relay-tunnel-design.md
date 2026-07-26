# Twitter API Safe Relay Tunnel Design

## Goal

Expose the `twitter-api-safe-mcp` stdio server to OpenAI products through
Secure MCP Tunnel on `B450M-Pro4`, without adding a publicly reachable relay
port or storing the runtime API key in the Nix store.

## Architecture

The existing `twitter-api-safe-relay` Podman container binds its application
port to `127.0.0.1:18788` on `B450M-Pro4`. Port 3000 is already used by Gitea.
It remains the backend for the existing Traefik route and Twitter Lite.

The NUR-packaged `twitter-api-safe-mcp` process now embeds the relay rather than
forwarding requests to the Podman container. A dedicated MCP settings file uses
the same generated browser profiles as the container and connects directly to
the CDP proxies. It selects stdio transport and disables only the MCP process's
dashboard listener. The
`openai-secure-tunnel-nix` NixOS module supervises the MCP process over stdio
and relays MCP requests through the OpenAI-hosted control plane.

The request path is:

```text
OpenAI Secure MCP Tunnel
  -> tunnel-client on B450M-Pro4
  -> twitter-api-safe-mcp (stdio)
  -> per-account CDP proxies
  -> logged-in Chrome containers
```

The existing Traefik route continues to use the separate
`twitter-api-safe-relay` container.

## Configuration

- Add `github:nakasyou/openai-secure-tunnel-nix` as a flake input following the
  repository's `nixpkgs` input.
- Import its `nixosModules.tunnel-client` module from the existing
  `twitter-api-safe-relay` service module.
- Configure one tunnel instance named `twitter-api-safe-relay` with tunnel ID
  `tunnel_6a605119f2bc8191b8aa9ffe352e095c` and health listener
  `127.0.0.1:18789`.
- Bind container port 3000 to host loopback port 18788.
- Bind `pkgs.twitter-api-safe-mcp` to a local `package` variable and run
  `${package}/bin/twitter-api-safe-mcp /run/twitter-api-safe-relay/mcp-settings.json`
  as the `main` stdio MCP command.
- Preserve `settings.json` for the relay container and generate a separate
  `mcp-settings.json` with `"mcp": { "transport": "stdio" }` and
  `"dashboard": false`. Send MCP process logs to stderr so stdout remains
  dedicated to the stdio JSON-RPC transport.
- Order the tunnel service after the relay container service.

## Secret Handling

Declare the sops secret `openai-tunnel-api-key` in the B450M-Pro4 secrets file.
Load its decrypted path into the generated tunnel service as the
`control-plane-api-key` systemd credential. The tunnel configuration points
`control_plane.api_key` directly at that credential with a `file:` reference,
so the runtime API key is not written to generated Nix configuration or the
Nix store.

The pinned Nix module's `apiKeyFile` option is intentionally not used. It
generates an environment reference whose value is another file reference, but
the tunnel client resolves only one reference layer and would send the literal
file reference as the bearer token.

The service module can be evaluated and built before the encrypted value is
added. Activation requires the user to add the value to
`systems/nixos/B450M-Pro4/secrets.yaml` using `sops set --value-stdin`.

## Failure Behavior and Operations

The tunnel service starts after networking and the relay container. It restarts
on failure using the upstream module defaults. The tunnel client exposes its
health and readiness endpoints only on loopback. Operators inspect the service
with `systemctl status` and `journalctl`; no new public health endpoint is
created.

## Verification

- Confirm the flake input resolves and the lock file contains it.
- Evaluate the B450M-Pro4 tunnel instance, stdio command, generated settings,
  secret path, systemd ordering, and loopback-only container port.
- Build the B450M-Pro4 system closure without activating it.
- Run `git diff --check` and confirm unrelated worktree changes are untouched.
