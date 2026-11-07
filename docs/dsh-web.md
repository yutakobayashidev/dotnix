# DeepSeek Harness Web

The Web UI is available at <https://dsh.home.yutakobayashi.com/> from the
Tailnet after both hosts have applied this configuration.

- UM790-Pro runs `dsh-web.service` as the Home Manager user, listening on
  `100.91.91.87:3081`. It uses the same `pkgs.llm-agents.dsh` package and
  `~/.dsh` configuration as the CLI, with the user's home as its working directory.
- B450M-Pro4 terminates HTTPS in Traefik and forwards to
  `http://um790-pro.tail29d068.ts.net:3081`. Its router allows only Tailnet clients.
- Existing wildcard DNS resolves the hostname to B450M-Pro4. No new firewall
  opening is needed: the backend binds only to UM790-Pro's Tailnet address.
- User lingering starts the service without an interactive login. A failed bind
  while Tailscale is starting is retried after five seconds.

The service passes `--public-url` and `--trusted-host` for the HTTPS hostname.
The public URL advertises the browser endpoint; the trusted host admits requests
through dsh's API host/origin checks. Neither replaces dsh's connection token.

## Sign-in and verification

On UM790-Pro, inspect the service and open the authenticated URL printed at startup:

```bash
systemctl --user status dsh-web
journalctl --user -u dsh-web -b -n 100
```

Treat the token-bearing URL as a credential; do not share the logs. Restarting
the service may require opening the newly printed URL. Model credentials and
profiles must be configured for the UM790-Pro user in dsh; this module does not
provision a DeepSeek API key. A browser sign-in alone does not provide a model
API credential.

From a Tailnet client, check the HTTPS entry point:

```bash
curl -I https://dsh.home.yutakobayashi.com/
```

Then open the authenticated URL and verify the UI can load sessions and execute
a turn using the configured model. On B450M-Pro4, inspect proxy failures with
`journalctl -u traefik -b`. A successful HTTP response alone does not verify model
authentication or tool execution.

Configuration lives in `modules/features/super-intelligence/dsh/default.nix`,
`homes/nixos/UM790-Pro/default.nix`, and `systems/nixos/services/dsh-web/default.nix`.
Both hosts use the existing Comin deployment workflow.
