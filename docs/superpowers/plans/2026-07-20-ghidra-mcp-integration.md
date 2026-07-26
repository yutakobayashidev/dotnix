# GhidraMCP Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package the GhidraMCP 1.1 stdio bridge and configure the ThinkPad's MCP clients to use it with an extension-enabled Ghidra on port 38473.

**Architecture:** Keep the Ghidra extension and Python bridge as separate NUR packages. The Home Manager MCP feature composes Ghidra 11.3.1 with the extension, registers the bridge through `mcp-servers-nix`, and exposes host/port options while the ThinkPad host enables the integration.

**Tech Stack:** Nix, Home Manager, mcp-servers-nix, Python FastMCP, Ghidra 11.3.1

## Global Constraints

- Use GhidraMCP version `1.1` and the existing release hash `sha256-WHwlwo8sV7t9irFKg0gOOzL04wvfhf+WElRVa9lAnus=`.
- Keep `ghidra-mcp` as the Ghidra extension package and add `ghidra-mcp-bridge` as a separate executable package.
- Use `127.0.0.1:38473` by default; do not expose the Ghidra HTTP API on a non-loopback address by default.
- Enable the integration only for `ThinkPad-X1-Carbon-Gen13`.
- Do not check a local path into `flake.lock`; publish NUR before updating the dotnix input.

---

### Task 1: Package the stdio bridge in nur-packages

**Files:**

- Create: `../nur-packages/pkgs/ghidra-mcp-bridge/default.nix`
- Modify: `../nur-packages/default.nix`
- Modify: `../nur-packages/README.md`

**Interfaces:**

- Consumes: the GhidraMCP 1.1 outer release archive and `python3Packages.{mcp,requests}`
- Produces: `pkgs.ghidra-mcp-bridge` with executable `bin/ghidra-mcp-bridge`

- [ ] **Step 1: Verify the package is absent**

Run:

```bash
cd ../nur-packages
nix eval --raw .#ghidra-mcp-bridge.pname
```

Expected: evaluation fails because `ghidra-mcp-bridge` does not exist.

- [ ] **Step 2: Add the bridge derivation**

Create `pkgs/ghidra-mcp-bridge/default.nix`:

```nix
{
  lib,
  fetchurl,
  makeWrapper,
  python3,
  stdenvNoCC,
  unzip,
}:

let
  pythonEnv = python3.withPackages (ps: [
    ps.mcp
    ps.requests
  ]);
in
stdenvNoCC.mkDerivation rec {
  pname = "ghidra-mcp-bridge";
  version = "1.1";

  src = fetchurl {
    url = "https://github.com/LaurieWired/GhidraMCP/releases/download/${version}/GhidraMCP-release-1-1.zip";
    hash = "sha256-WHwlwo8sV7t9irFKg0gOOzL04wvfhf+WElRVa9lAnus=";
  };

  dontUnpack = true;
  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/ghidra-mcp"
    unzip -p "$src" bridge_mcp_ghidra.py > "$out/share/ghidra-mcp/bridge_mcp_ghidra.py"
    makeWrapper "${pythonEnv}/bin/python" "$out/bin/ghidra-mcp-bridge" \
      --add-flags "$out/share/ghidra-mcp/bridge_mcp_ghidra.py"

    runHook postInstall
  '';

  meta = {
    description = "MCP stdio bridge for the GhidraMCP extension";
    homepage = "https://github.com/LaurieWired/GhidraMCP";
    license = lib.licenses.asl20;
    mainProgram = "ghidra-mcp-bridge";
  };
}
```

- [ ] **Step 3: Export and document the package**

Add after `ghidra-mcp` in `../nur-packages/default.nix`:

```nix
  ghidra-mcp-bridge = pkgs.callPackage ./pkgs/ghidra-mcp-bridge { };
```

Add `ghidra-mcp-bridge` immediately after `ghidra-mcp` in the README package
list, then append this paragraph to the GhidraMCP usage section:

```markdown
`ghidra-mcp` provides the extension loaded into Ghidra. MCP clients launch the
separate `ghidra-mcp-bridge` executable, which forwards stdio MCP requests to
the extension's HTTP endpoint.
```

- [ ] **Step 4: Format, build, and smoke-test**

Run:

```bash
nix run nixpkgs#nixfmt -- default.nix pkgs/ghidra-mcp-bridge/default.nix
nix eval --raw .#ghidra-mcp-bridge.pname
nix build .#ghidra-mcp-bridge
timeout 5 result/bin/ghidra-mcp-bridge </dev/null
git diff --check
```

Expected: evaluation prints `ghidra-mcp-bridge`, the build succeeds, and the
bridge exits cleanly on stdin EOF without contacting Ghidra.

- [ ] **Step 5: Commit the NUR package**

```bash
git add README.md default.nix pkgs/ghidra-mcp-bridge/default.nix
git commit -m "feat: add ghidra-mcp bridge"
```

### Task 2: Publish NUR and update the dotnix input

**Files:**

- Modify: `flake.lock`

**Interfaces:**

- Consumes: committed `ghidra-mcp` and `ghidra-mcp-bridge` packages on NUR `main`
- Produces: a dotnix `nur-packages` lock entry containing both packages

- [ ] **Step 1: Publish the NUR main branch**

Run from `../nur-packages`:

```bash
git push origin main
```

Expected: the remote branch advances through the bridge package commit.

- [ ] **Step 2: Update only the NUR lock entry**

Run from dotnix:

```bash
nix flake update nur-packages
nix eval --raw .#nixosConfigurations.ThinkPad-X1-Carbon-Gen13.pkgs.ghidra-mcp-bridge.pname
```

Expected: only the `nur-packages` lock node changes and evaluation prints
`ghidra-mcp-bridge`.

### Task 3: Add declarative GhidraMCP Home Manager options

**Files:**

- Modify: `modules/features/coding-agents/mcp.nix`
- Modify: `modules/features/coding-agents/codex/default.nix`
- Modify: `homes/nixos/ThinkPad-X1-Carbon-Gen13/default.nix`
- Create: `docs/ghidra-mcp.md`
- Modify: `CLAUDE.md`

**Interfaces:**

- Consumes: `pkgs.ghidra-mcp`, `pkgs.ghidra-mcp-bridge`, and `mcp-servers-nix.homeManagerModules.default`
- Produces: `my.programs.mcp.ghidra.{enable,host,port}`, an extension-enabled Ghidra package, and `programs.mcp.servers.ghidra`

- [ ] **Step 1: Verify the option is absent**

Run:

```bash
nix eval --json .#nixosConfigurations.ThinkPad-X1-Carbon-Gen13.config.home-manager.users.yuta.programs.mcp.servers.ghidra
```

Expected: evaluation fails because the `ghidra` MCP server is not configured.

- [ ] **Step 2: Add the module options and configuration**

Replace `modules/features/coding-agents/mcp.nix` with:

```nix
_:

{
  flake.modules.homeManager."mcp" =
    {
      inputs,
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.mcp;
      ghidraWithMcp = pkgs.ghidra-mcp.ghidra.withExtensions (_: [ pkgs.ghidra-mcp ]);
    in
    {
      imports = [ inputs.mcp-servers-nix.homeManagerModules.default ];

      options.my.programs.mcp = {
        enable = lib.mkEnableOption "Model Context Protocol Servers";

        ghidra = {
          enable = lib.mkEnableOption "GhidraMCP integration";
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Host running the GhidraMCP HTTP extension.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 38473;
            description = "Port used by the GhidraMCP HTTP extension.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = lib.optional cfg.ghidra.enable ghidraWithMcp;

        programs.mcp = {
          enable = true;

          servers = {
            deepwiki = {
              url = "https://mcp.deepwiki.com/mcp";
            };
          };
        };

        mcp-servers = {
          programs = {
            context7.enable = true;
            playwright.enable = true;
            time = {
              enable = true;
              args = [ "--local-timezone=Asia/Tokyo" ];
            };
          };

          settings.servers = lib.mkIf cfg.ghidra.enable {
            ghidra = {
              command = lib.getExe pkgs.ghidra-mcp-bridge;
              args = [ "http://${cfg.ghidra.host}:${toString cfg.ghidra.port}" ];
            };
          };
        };
      };
    };
}
```

Replace the two dotted `mcp_servers` assignments in
`modules/features/coding-agents/codex/default.nix` with:

```nix
mcp_servers =
  {
    deepwiki = {
      url = "https://mcp.deepwiki.com/mcp";
    };
  }
  // lib.optionalAttrs (config.my.programs.mcp.enable && config.my.programs.mcp.ghidra.enable) {
    ghidra = {
      inherit (config.programs.mcp.servers.ghidra) command args;
    };
  };
```

- [ ] **Step 3: Enable GhidraMCP on the ThinkPad**

Add inside the ThinkPad user's Home Manager configuration:

```nix
my.programs.mcp.ghidra.enable = true;
```

- [ ] **Step 4: Document the required Ghidra-side setting**

Create `docs/ghidra-mcp.md`:

```markdown
# GhidraMCP

The ThinkPad configuration installs Ghidra 11.3.1 with the GhidraMCP 1.1
extension and registers its stdio bridge with Home Manager's MCP registry.

## First-time setup

1. Start Ghidra and open a CodeBrowser tool.
2. Enable `GhidraMCPPlugin` under `File -> Configure -> Developer`.
3. Set `Edit -> Tool Options -> GhidraMCP HTTP Server -> Server Port` to
   `38473`.
4. Reload the plugin or restart Ghidra, then open the program to analyze.
5. Start an MCP client. Home Manager supplies the bridge command and its
   `http://127.0.0.1:38473` endpoint.

The bridge starts on demand, but tool calls require Ghidra to be running with
the plugin enabled and a program open.
```

Change the NixOS development bullet in `CLAUDE.md` to:

```markdown
- **Development**: Docker, Tailscale, Android dev environment, VirtualBox on UM790-Pro, and [GhidraMCP integration](docs/ghidra-mcp.md)
```

- [ ] **Step 5: Evaluate the generated MCP entry**

Run:

```bash
nix eval --json .#nixosConfigurations.ThinkPad-X1-Carbon-Gen13.config.home-manager.users.yuta.programs.mcp.servers.ghidra
```

Expected JSON contains the Nix store command ending in
`/bin/ghidra-mcp-bridge` and exactly this argument:

```json
["http://127.0.0.1:38473"]
```

Evaluate `home.activation.writeCodexConfig.data`, realise the referenced
`codex-config` store path, and verify it also contains
`[mcp_servers.ghidra]` with the same command and argument.

- [ ] **Step 6: Build and verify the ThinkPad configuration**

Run:

```bash
nix run nixpkgs#nixfmt -- modules/features/coding-agents/mcp.nix modules/features/coding-agents/codex/default.nix homes/nixos/ThinkPad-X1-Carbon-Gen13/default.nix
nix build .#nixosConfigurations.ThinkPad-X1-Carbon-Gen13.config.system.build.toplevel --no-link
git diff --check
```

Expected: formatting and the full system build succeed with no whitespace
errors.

- [ ] **Step 7: Commit the dotnix integration**

```bash
git add AGENTS.md docs/ghidra-mcp.md docs/superpowers/plans/2026-07-20-ghidra-mcp-integration.md docs/superpowers/specs/2026-07-20-ghidra-mcp-integration-design.md flake.lock homes/nixos/ThinkPad-X1-Carbon-Gen13/default.nix modules/features/coding-agents/codex/default.nix modules/features/coding-agents/mcp.nix
git commit -m "feat: configure ghidra-mcp"
```

### Task 4: Final cross-repository verification

**Files:**

- Verify only

**Interfaces:**

- Consumes: committed and published NUR package plus committed dotnix configuration
- Produces: evidence that the complete extension-to-bridge integration evaluates and builds

- [ ] **Step 1: Verify repository state and runtime artifacts**

Run:

```bash
git -C ../nur-packages status --short --branch
git status --short --branch
nix eval --json .#nixosConfigurations.ThinkPad-X1-Carbon-Gen13.config.home-manager.users.yuta.programs.mcp.servers.ghidra
nix build .#nixosConfigurations.ThinkPad-X1-Carbon-Gen13.config.system.build.toplevel --no-link
```

Expected: both worktrees are clean, the configured URL uses port 38473, and
the ThinkPad system derivation builds successfully.
