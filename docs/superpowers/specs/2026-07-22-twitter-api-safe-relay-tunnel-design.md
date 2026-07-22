# Twitter API Safe Relay Tunnel Design

## Goal

Expose the `twitter-api-safe-relay-mcp` stdio server to OpenAI products through
Secure MCP Tunnel on `B450M-Pro4`, without adding a publicly reachable relay
port or storing the runtime API key in the Nix store.

## Architecture

The existing `twitter-api-safe-relay` Podman container binds its application
port to `127.0.0.1:18788` on `B450M-Pro4`. Port 3000 is already used by Gitea.
The NUR-packaged
`twitter-api-safe-relay-mcp` process calls that loopback endpoint. The
`openai-secure-tunnel-nix` NixOS module supervises the MCP process over stdio
and relays MCP requests through the OpenAI-hosted control plane.

The request path is:

```text
OpenAI Secure MCP Tunnel
  -> tunnel-client on B450M-Pro4
  -> twitter-api-safe-relay-mcp (stdio)
  -> http://127.0.0.1:18788
  -> twitter-api-safe-relay container
```

The existing Traefik route remains unchanged.

## Configuration

- Add `github:nakasyou/openai-secure-tunnel-nix` as a flake input following the
  repository's `nixpkgs` input.
- Import its `nixosModules.tunnel-client` module from the existing
  `twitter-api-safe-relay` service module.
- Configure one tunnel instance named `twitter-api-safe-relay` with tunnel ID
  `tunnel_6a605119f2bc8191b8aa9ffe352e095c` and health listener
  `127.0.0.1:18789`.
- Bind container port 3000 to host loopback port 18788.
- Bind `pkgs.twitter-api-safe-relay-mcp` to a local `package` variable and run
  `${package}/bin/twitter_api_safe_relay_mcp` as the `main` stdio MCP command.
- Set the non-secret `TWITTER_RELAY_BASE_URL` environment variable to
  `http://127.0.0.1:18788`.
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
- Evaluate the B450M-Pro4 tunnel instance, stdio command, environment, secret
  path, systemd ordering, and loopback-only container port.
- Build the B450M-Pro4 system closure without activating it.
- Run `git diff --check` and confirm unrelated worktree changes are untouched.
