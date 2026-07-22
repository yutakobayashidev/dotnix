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
