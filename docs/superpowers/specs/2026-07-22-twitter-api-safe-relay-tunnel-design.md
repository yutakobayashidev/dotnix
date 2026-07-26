# Twitter API Safe Relay Tunnel Design

## Goal

Expose `twitter-api-safe-mcp` to OpenAI products through Secure MCP Tunnel on
`B450M-Pro4`, without adding a publicly reachable relay port or storing the
runtime API key in the Nix store.

## Architecture

The NUR-packaged `twitter-api-safe-mcp` process runs as a native NixOS systemd
service on `127.0.0.1:18788`. It embeds the HTTP relay, dashboard, and
Streamable HTTP MCP endpoint in one process. That process is the single owner
of the generated browser profiles and connects directly to the CDP proxies.
The previous relay container and separate stdio MCP process were removed to
avoid two Playwright clients concurrently controlling the same browser page.

Traefik and Twitter Lite continue to use the relay on port 18788. The
`openai-secure-tunnel-nix` NixOS module connects to its loopback-only `/mcp`
endpoint and relays MCP requests through the OpenAI-hosted control plane.

The request path is:

```text
OpenAI Secure MCP Tunnel
  -> tunnel-client on B450M-Pro4
  -> twitter-api-safe-mcp /mcp (Streamable HTTP)
  -> per-account CDP proxies
  -> logged-in Chrome containers
```

The existing Traefik route and Twitter Lite use the same process's HTTP relay.

## Configuration

- Add `github:nakasyou/openai-secure-tunnel-nix` as a flake input following the
  repository's `nixpkgs` input.
- Import its `nixosModules.tunnel-client` module from the existing
  `twitter-api-safe-relay` service module.
- Configure one tunnel instance named `twitter-api-safe-relay` with tunnel ID
  `tunnel_6a605119f2bc8191b8aa9ffe352e095c` and health listener
  `127.0.0.1:18789`.
- Run `pkgs.twitter-api-safe-mcp` as `twitter-api-safe-relay.service` with one
  generated settings file, loopback hostname, port 18788, dashboard enabled,
  and `"mcp": { "transport": "http" }`.
- Route `tw.home.yutakobayashi.com` through native Traefik dynamic
  configuration to `http://127.0.0.1:18788`.
- Configure the tunnel's `main` MCP server URL as
  `http://127.0.0.1:18788/mcp`.
- Order the tunnel and Twitter Lite services after
  `twitter-api-safe-relay.service`.

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

The relay service starts after the CDP proxy containers and restarts on
failure. The tunnel service starts after the relay and uses the upstream module
restart defaults. Both the relay and tunnel health endpoints are loopback-only.
Operators inspect the services with `systemctl status` and `journalctl`; no new
public health endpoint is created.

## Verification

- Confirm the flake input resolves and the lock file contains it.
- Evaluate the B450M-Pro4 tunnel URL, generated HTTP MCP settings, native
  service command, Traefik backend, secret path, and systemd ordering.
- Verify the relay health endpoint, `/mcp` initialization through the tunnel,
  and a read-only Twitter tool call after activation.
- Build the B450M-Pro4 system closure without activating it.
- Run `git diff --check` and confirm unrelated worktree changes are untouched.
