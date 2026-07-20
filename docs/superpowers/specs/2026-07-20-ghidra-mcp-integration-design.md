# GhidraMCP Integration Design

## Goal

Make GhidraMCP 1.1 usable from MCP clients managed by dotnix on the current
ThinkPad host.

## Architecture

GhidraMCP has two runtime components with separate responsibilities:

1. The `ghidra-mcp` Ghidra extension runs inside Ghidra and exposes an HTTP API.
2. The `ghidra-mcp-bridge` process speaks MCP over stdio and forwards tool calls
   to that HTTP API.

Keep these as separate NUR packages. The existing extension package remains an
input to `ghidra.withExtensions`, while the bridge package provides the
`ghidra-mcp-bridge` executable and its Python dependencies.

## Port Configuration

GhidraMCP 1.1 uses port 8080 upstream by default on both sides. The release's
Python bridge defaults to `http://127.0.0.1:8080/`, and the compiled extension
registers 8080 as its `Server Port` default. Use `38473` in dotnix to avoid that
common application port. The port is absent from the repository's host and
service declarations and was not listening on the reachable managed hosts when
the integration was designed.

Expose Home Manager-style options under `my.programs.mcp.ghidra`:

- `enable`: whether to install and register GhidraMCP
- `host`: HTTP host used by the bridge, defaulting to `127.0.0.1`
- `port`: HTTP port used by the bridge, defaulting to `38473`

This keeps the bridge endpoint configurable without duplicating raw MCP server
settings in host files.

## dotnix Integration

When both `my.programs.mcp.enable` and `my.programs.mcp.ghidra.enable` are true:

- add Ghidra 11.3.1 composed with `pkgs.ghidra-mcp` to `home.packages`;
- register `pkgs.ghidra-mcp-bridge` through
  `mcp-servers.settings.servers.ghidra`;
- pass `http://<host>:<port>/` as the bridge's positional argument.

Enable the integration only in the ThinkPad Home Manager configuration. Other
development-profile hosts keep their current MCP and package sets.

## Repository Sequencing

Add and verify `ghidra-mcp-bridge` in `nur-packages`, publish the NUR commit, then
update dotnix's `nur-packages` lock entry before evaluating the ThinkPad
configuration. This avoids checking in a local path dependency.

## Runtime Behavior

The MCP client starts the bridge on demand. Ghidra must already be running with
a program open and `GhidraMCPPlugin` enabled. If Ghidra is stopped or the port
does not match, the bridge remains available but tool calls return connection
errors. Because the extension stores its port in Ghidra's tool configuration,
set `Edit -> Tool Options -> GhidraMCP HTTP Server -> Server Port` to `38473`
once after enabling the plugin; dotnix configures the bridge side declaratively.

## Verification

- Build and smoke-test the bridge package's MCP initialization.
- Build the extension-composed Ghidra package.
- Evaluate the generated Home Manager MCP server entry and confirm its command
  and URL argument.
- Build the ThinkPad system configuration with the updated NUR input.
- Run formatting and repository diff checks before committing.
