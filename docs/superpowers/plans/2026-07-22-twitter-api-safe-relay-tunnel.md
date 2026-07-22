# Twitter API Safe Relay Tunnel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run the NUR-packaged Twitter API Safe Relay MCP server behind OpenAI Secure MCP Tunnel on B450M-Pro4.

**Architecture:** The relay container exposes port 3000 only as host loopback port 18788. The tunnel-client NixOS module launches the MCP package over stdio and injects the OpenAI runtime key from sops through a systemd credential.

**Tech Stack:** Nix flakes, NixOS modules, Podman, systemd, sops-nix, OpenAI tunnel-client, MCP stdio

## Global Constraints

- Use tunnel ID `tunnel_6a605119f2bc8191b8aa9ffe352e095c`.
- Listen for tunnel health only on `127.0.0.1:18789`.
- Expose the relay container only on `127.0.0.1:18788`.
- Keep the runtime API key out of the Nix store and command-line arguments.
- Preserve all unrelated staged Neovim changes and the untracked `course-cli/` directory.

---

### Task 1: Add the tunnel-client flake input

**Files:**

- Modify: `flake.nix`
- Modify: `flake.lock`

**Interfaces:**

- Produces: `inputs.openai-secure-tunnel-nix.nixosModules.tunnel-client`

- [ ] **Step 1: Add the flake input**

Add this input beside `nur-packages`:

```nix
openai-secure-tunnel-nix = {
  url = "github:nakasyou/openai-secure-tunnel-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

- [ ] **Step 2: Update only the new input in the lock file**

Run:

```bash
env XDG_CACHE_HOME=/tmp/dotnix-nix-cache nix flake lock --update-input openai-secure-tunnel-nix
```

Expected: `flake.lock` gains the new input and its required dependency nodes; the existing `nur-packages` update remains intact.

- [ ] **Step 3: Check the focused diff**

Run:

```bash
git diff -- flake.nix flake.lock
```

Expected: only the input addition plus lock changes for `openai-secure-tunnel-nix` and the pre-existing `nur-packages` update.

### Task 2: Configure the relay and secure tunnel service

**Files:**

- Modify: `systems/nixos/services/twitter-api-safe-relay/default.nix`

**Interfaces:**

- Consumes: `inputs.openai-secure-tunnel-nix.nixosModules.tunnel-client`
- Consumes: `pkgs.twitter-api-safe-relay-mcp`
- Consumes: `config.sops.secrets.openai-tunnel-api-key.path`
- Produces: `systemd.service.tunnel-client-twitter-api-safe-relay`

- [ ] **Step 1: Extend the module arguments and local bindings**

Use `config` and `inputs`, define the loopback port, and bind the package:

```nix
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  relayHostPort = 18788;
  package = pkgs.twitter-api-safe-relay-mcp;
```

- [ ] **Step 2: Import and configure tunnel-client**

Add the upstream NixOS module, sops secret, and instance:

```nix
imports = [ inputs.openai-secure-tunnel-nix.nixosModules.tunnel-client ];

sops.secrets.openai-tunnel-api-key = {
  sopsFile = ../../B450M-Pro4/secrets.yaml;
};

services.openai-tunnel-client.instances.twitter-api-safe-relay = {
  enable = true;
  environment.TWITTER_RELAY_BASE_URL = "http://127.0.0.1:${toString relayHostPort}";
  settings = {
    config_version = 1;
    control_plane = {
      tunnel_id = "tunnel_6a605119f2bc8191b8aa9ffe352e095c";
      api_key = "file:/run/credentials/tunnel-client-twitter-api-safe-relay.service/control-plane-api-key";
    };
    health.listen_addr = "127.0.0.1:18789";
    admin_ui.open_browser = false;
    mcp.commands = [
      {
        channel = "main";
        command = "${package}/bin/twitter_api_safe_relay_mcp";
      }
    ];
  };
};
```

- [ ] **Step 3: Publish the relay only on loopback**

Add to the `twitter-api-safe-relay` container:

```nix
ports = [ "127.0.0.1:${toString relayHostPort}:3000" ];
```

- [ ] **Step 4: Order tunnel startup after the relay**

Augment the generated unit without replacing upstream hardening:

```nix
systemd.services.tunnel-client-twitter-api-safe-relay = {
  after = [ "podman-twitter-api-safe-relay.service" ];
  wants = [ "podman-twitter-api-safe-relay.service" ];
  serviceConfig.LoadCredential = [
    "control-plane-api-key:${config.sops.secrets.openai-tunnel-api-key.path}"
  ];
};
```

The direct `file:` reference avoids the pinned module's nested
environment-to-file reference, which the tunnel client does not resolve.

- [ ] **Step 5: Evaluate the exact configuration**

Run focused `nix eval --json` checks for the container port, tunnel settings, environment, credential path, and unit ordering. Expected values must match the Global Constraints and the package path must end in `/bin/twitter_api_safe_relay_mcp`.

### Task 3: Document and verify the system closure

**Files:**

- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-07-22-twitter-api-safe-relay-tunnel-design.md`
- Modify: `z-ai/lessons.md`

**Interfaces:**

- Produces: operator-visible feature documentation and verified NixOS closure

- [ ] **Step 1: Update the feature list**

Add Twitter API Safe Relay with Secure MCP Tunnel to the B450M-Pro4 self-hosted services entry in `README.md`.

- [ ] **Step 2: Format changed Nix files**

Run:

```bash
nixfmt flake.nix systems/nixos/services/twitter-api-safe-relay/default.nix
```

Expected: exit 0 with only formatting changes.

- [ ] **Step 3: Build the B450M-Pro4 system closure**

Run:

```bash
env XDG_CACHE_HOME=/tmp/dotnix-nix-cache nix build path:.#nixosConfigurations.B450M-Pro4.config.system.build.toplevel --no-link
```

Expected: exit 0. Activation is intentionally deferred until the runtime key is added to sops.

- [ ] **Step 4: Run final diff checks**

Run:

```bash
git diff --check
git status --short
```

Expected: no whitespace errors; unrelated pre-existing changes remain untouched.

- [ ] **Step 5: Provide the safe secret command**

Give the user this interactive command after implementation:

```bash
read -rsp 'OpenAI tunnel runtime API key: ' openai_tunnel_key; printf '\n'; printf '%s' "$openai_tunnel_key" | jq -Rs . | sops set --value-stdin systems/nixos/B450M-Pro4/secrets.yaml '["openai-tunnel-api-key"]'; unset openai_tunnel_key
```

The key is read silently, passed over stdin, omitted from shell history and process arguments, and never written to a temporary file.
