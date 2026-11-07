# DeepSeek Harness Web

The Web UI is available at <https://dsh.home.yutakobayashi.com/> from the
Tailnet after both hosts have applied this configuration.

- UM790-Pro runs `dsh-web.service` as the Home Manager user on loopback
  `127.0.0.1:3082`. A same-user lighttpd proxy listens on `100.91.91.87:3081`
  and automates browser sign-in. dsh uses the same `pkgs.llm-agents.dsh` package and
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

## Authentication policy

Automatic sign-in adapts [NixKits `reverseProxy.autoAuth`](https://github.com/Kihara777/NixKits/blob/deea6012ec713b808ed97b920e75033d872fb332/modules/dsh.nix).
The service captures its startup token in a private runtime directory. On a
homepage request without a dsh cookie, lighttpd redirects to the token URL;
dsh then issues its normal signed cookie. Open the ordinary HTTPS URL: no
manual log inspection or token copying is required. Host and WebSocket upgrades
are preserved, and dsh itself is not patched.

Any client allowed through the Tailnet restriction receives full owner access.
Pocket ID is not required for this network-trusted configuration. Keep both the
Tailnet-bound proxy and the Traefik source-IP restriction in place.

Revisit this when upstream supports OIDC or a supported browser authentication
provider API. Track [the upstream proposal](https://github.com/deepseek-ai/deepseek-harness/discussions/11419)
and its [single-owner provider API prototype](https://github.com/deepseek-ai/deepseek-harness/discussions/11419#discussioncomment-19399659).
The prototype is not a dependency of this configuration.

## Sign-in and verification

Open <https://dsh.home.yutakobayashi.com/> directly. To inspect the services on
UM790-Pro:

```bash
systemctl --user status dsh-web dsh-web-proxy
journalctl --user -u dsh-web -u dsh-web-proxy -b -n 100
```

The startup log and current token are stored under `$XDG_RUNTIME_DIR/dsh-web/`
with access restricted to the service user. They are refreshed on every start;
do not share them. The signing secret persists in `~/.dsh/.credentials.yaml`,
so existing cookies survive service restarts. An expired cookie is normally
removed by the browser and sign-in is automatic again. As in the reference
implementation, a corrupt cookie with a `dsh-auth-` name requires clearing the
site's cookies before reopening the homepage.

## Models and providers

`homes/nixos/UM790-Pro/dsh.nix` declares two native providers:

- `opencode-go`: direct OpenCode Go access using the bundled pi-ai model catalog
  and per-conversation session-header handling.
- `openai-codex`: direct ChatGPT/Codex access using its bundled model catalog and
  authentication implementation. Initial interactive sign-in in dsh is required;
  it does not reuse LiteLLM's credentials.

Both providers intentionally omit `api`, `baseURL`, and model overrides. Setting
an explicit `api` would replace the native provider dispatch with a generic
adapter and bypass OpenCode's session-header handling. Provider catalogs update
with the dsh package rather than copying legacy model names from LiteLLM.

OpenCode's existing key remains in
`systems/nixos/services/litellm/secrets.yaml`, encrypted for B450M-Pro4 and UM790-Pro.
Home Manager sops-nix renders a user-only `dsh-web.env` at runtime, and systemd
loads it through `EnvironmentFile` after `sops-nix.service`. The plaintext key
is not embedded in the Nix store or the unit definition.

The shared key is a service-account key from the Go workspace. Its replacement
was verified on 2026-11-07 with `billing_source: go` and `cost: 0`; see
[LiteLLM credential maintenance](litellm.md#verification-and-credentials). After
a key replacement is deployed, restart `dsh-web.service` so it reloads the
rendered environment file.

The duplicate `litellm-chat` and `litellm-responses` routes are removed. LiteLLM
itself remains available to other clients. Add a separate dsh route if local
models or other gateway-only models are needed; do not route these native
providers through it.

The existing default and per-session model selections are preserved. Select a
registered model in the UI as needed. dsh's separate web-search provider still needs its own configuration;
adding a model provider does not configure search.

`my.programs.dsh.web.settings` generates an upstream `--patch` overlay for the
Web service. This follows the declarative provider approach in
[codgician/serenitea-pot](https://github.com/codgician/serenitea-pot/blob/HEAD/hm-modules/codgi/generic/dsh/default.nix)
and the bundled Codex route in
[jadeezomg/flake](https://github.com/jadeezomg/flake/blob/9aef41879898327d12131afcc5c0b56e2b802265/modules/profiles/devenv/agents/dsh.nix).
The generated overlay takes precedence over saved profile settings; edit Nix
for persistent provider changes. Existing mutable profile files and
credential storage are preserved. Configuration contains credential references,
not upstream API keys. No model request is sent to Codex until it is selected.

### Model availability and validation

When switching from the former LiteLLM routes, select a native provider/model
for existing sessions that still reference `litellm-chat` or `litellm-responses`.
No default model or saved conversation is rewritten. Account authorization and
upstream availability still determine which catalog entries can actually run.

The previous generic OpenCode route omitted `x-opencode-session`, and the
LiteLLM ChatGPT registry contained rejected legacy model IDs. Native providers
avoid those overrides. OpenCode's [client requirements](https://opencode.ai/docs/console/go/#where-can-i-use-it)
require a stable session ID per conversation; no synthetic constant header or
custom adapter patch is used here.

## Endpoint verification

From a Tailnet client, check the HTTPS entry point:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://dsh.home.yutakobayashi.com/
```

An unauthenticated homepage request should return 302. Open the URL in a fresh
browser session and verify the UI can load sessions and execute a turn using
the configured model. On B450M-Pro4, inspect proxy failures with
`journalctl -u traefik -b`. A successful HTTP response alone does not verify model
authentication or tool execution.

Configuration lives in `modules/features/super-intelligence/dsh/default.nix`,
`homes/nixos/UM790-Pro/default.nix`, and `systems/nixos/services/dsh-web/default.nix`.
Both hosts use the existing Comin deployment workflow.
