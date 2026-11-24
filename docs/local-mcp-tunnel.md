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

## Atuin history and output search

UM790-Pro runs `tunnel-client-atuin-mcp` as the owner of the synchronized
Atuin client database. Its `main` channel launches `atuin mcp` over stdio.
B450M-Pro4 serves the Atuin sync protocol on port 8890. Search coverage
depends on which records and captured outputs are available on UM790-Pro.
Check `atuin status` and `atuin sync` as the history owner before relying on
it. The service sees only the user's Atuin configuration and data directories,
and needs write access to the data directory for SQLite.

The tunnel is `openai_mcp_tunnel.atuin_mcp` in tofu-configuration; its ID
(`tofu -chdir=infra/services/openai output -raw atuin_mcp_tunnel_id`) is set in
`systems/nixos/UM790-Pro/atuin-mcp.nix`. The runtime key comes from the existing
sops secret `openai-tunnel-api-key` through `LoadCredential`. Health and the
local admin UI listen on `127.0.0.1:18796` only.

1. In [Platform tunnel settings](https://platform.openai.com/settings/organization/tunnels),
   associate the `Atuin MCP` tunnel with the intended ChatGPT workspace. Limit
   access to people allowed to read this user's shell history, command output
   and agent threads.
2. After comin applies UM790-Pro, check the client:
   `curl -fsS http://127.0.0.1:18796/readyz`. The admin UI at
   `http://127.0.0.1:18796/ui` shows polling status. Use
   `journalctl -u tunnel-client-atuin-mcp -b` to diagnose startup failures.
3. In the associated ChatGPT workspace, add a custom MCP server named
   **Atuin**, choose **Connection → Tunnel**, and select `Atuin MCP`. Select
   **No authentication** for the stdio server. Review the access warning,
   create the plugin, and grant the intended users access. Verify discovery
   and approve an `atuin_history` search for a harmless test command recorded
   on UM790-Pro.

Responses API agents in the organization can register it in the request's
`tools` array:

```json
{
	"type": "mcp",
	"server_label": "atuin",
	"tunnel_id": "tunnel_6b05de9520148191b5e9dc1c08aa1c8e",
	"require_approval": "always"
}
```

Each host keeps its local `atuin mcp` registration in
`modules/features/super-intelligence/mcp.nix`, which searches that host's
own Atuin database. The tunnel adds remote access for clients that accept a
tunnel ID, such as ChatGPT and the Responses API.
[OpenAI Secure MCP Tunnel guide](https://developers.openai.com/api/docs/guides/secure-mcp-tunnels)
