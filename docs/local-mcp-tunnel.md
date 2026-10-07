# local-mcp OpenAI tunnel

UM790-Pro runs the upstream `nakasyou/local-mcp` package behind a dedicated
OpenAI Secure MCP Tunnel instance. The service exposes only `/home/yuta/ghq`
from the user's home directory; systemd hides the rest of `/home`.

The MCP server stores permits and its approval socket in `/var/lib/local-mcp`.
Handle one-time approval requests on UM790-Pro with:

```bash
XDG_STATE_HOME=/var/lib/local-mcp local-mcp approvals
```

The systemd service is `tunnel-client-local-mcp`. Its health endpoint listens
only on `127.0.0.1:18790`.

The OpenAI control-plane key is stored in `secrets/openai-tunnel.yaml`, encrypted
only for B450M-Pro4 and UM790-Pro so both tunnel clients can consume it.

## Personal Workspace

UM790-Pro also runs `tunnel-client-personal-workspace`, declared in
`systems/nixos/UM790-Pro/personal-workspace-tunnel.nix`. This separate OpenAI
Tunnel forwards to the app's Streamable HTTP MCP endpoint at
`http://100.91.91.87:3006/mcp`, using tunnel ID
`tunnel_6ac62e4088bc8191ba2fbc6648c0171b`. Its health endpoint listens only on
`127.0.0.1:18791`.

The system service loads the same sops-managed OpenAI API key through systemd
`LoadCredential`. It starts at boot and restarts on failure. No separate
user-managed tunnel configuration or copied API key is needed. The app and its
Codex app-server remain Home Manager user services; `TWITTER_LITE_MCP_URL` points
Research tool calls at the app's own HTTP endpoint. App MCP authentication is
currently disabled.
