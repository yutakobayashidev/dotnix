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

`homes/nixos/UM790-Pro/dsh.nix` enables the following providers:

- `opencode-go`: direct OpenCode Go access using the bundled pi-ai model catalog
  and per-conversation session-header handling.
- `openai-codex`: owned by the Nix-packaged `dsh-codex-subscription` 3.2.24
  plugin. Open **Settings → Codex** and choose device-code sign-in when the
  browser is on a different machine from UM790-Pro. Complete ChatGPT approval
  yourself, then select a Codex model in the conversation. Credentials remain
  in DSH's private host credential service; Codex CLI credentials are not copied.

The native OpenCode provider intentionally omits `api`, `baseURL`, and model overrides. Setting
an explicit `api` would replace the native provider dispatch with a generic
adapter and bypass OpenCode's session-header handling. OpenCode's catalog updates with dsh; the subscription plugin discovers Codex models
from the signed-in account.

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

### Codex subscription plugin

`my.programs.dsh.web.codexSubscription.enable` loads the pinned NUR package
through the declarative Web patch. Its networking dependencies are locked; DSH
and Pi peer modules come from the running host package to avoid duplicate
service identities. No runtime npm installation is required. Do not also declare
`openai-codex` under `llm-pi-ai.providers`: both would register the same route.

The initial configuration disables subscription tools for other models and
image generation/editing. Remote control and connectors retain their upstream
off defaults. Authentication is an interactive user action, separate from
deployment; seeing the sign-in page does not establish account/model access.

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

## Research MCP servers

`homes/nixos/UM790-Pro/dsh.nix` inserts ClinicalTrials.gov, Crossref, OpenAlex,
PubMed, Semantic Scholar, and Unpaywall into the Web profile through
`my.programs.dsh.web.mcpServers`. Local servers use Bun's package runner with
an explicit Node.js/Bun PATH; Crossref uses Streamable HTTP without configured
OAuth. Package versions follow the supplied configuration and are downloaded
at runtime, so first startup needs network access and can exceed the 30-second
startup timeout. Restart the service after resolving a failed initial startup.

Oura is intentionally omitted. Elsevier was disabled in the supplied config
and is not inserted; its `/root/health` executable is not available here.

OpenAlex, PubMed, and Semantic Scholar start without API keys. Anonymous
access has lower rate limits; keys can be added later if needed.

The standalone Unpaywall server and PubMed's Unpaywall full-text fallback
receive the configured contact email through `UNPAYWALL_EMAIL`. This is a
contact address sent with API requests, not an API secret. No credential
registration is needed for the current configuration.

Optional keys are `OPENALEX_API_KEY`, `NCBI_API_KEY`, and
`SEMANTIC_SCHOLAR_API_KEY`. Add their transport environment references only
when they are actually provisioned, using DSH's `${credential:NAME}` syntax
with `expandTemplates = true`. Do not put plaintext API keys in Nix.

After deployment, check the Web profile for `mcp__<serverName>__<tool>` tools
and inspect `journalctl --user -u dsh-web -b` for discovery failures. Schema
validation does not establish API authentication or successful tool calls.

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

## Grafana usage metrics

The managed CLI and Web service load a numeric-only metrics plugin by default.
The [Coding Agents dashboard](https://grafana.home.yutakobayashi.com/d/coding-agents)
has a dsh row for tokens, requests, outcomes and duration. See
[agent monitoring](agent-monitoring.md) for scope, privacy and export limitations.
Disable it with `my.programs.dsh.telemetry.enable = false`.

## Herdr integration

UM790-Pro enables `my.programs.dsh.web.herdrBridge.enable`. The Web service loads
[dsh-herdr-bridge](https://github.com/Hariketsu/dsh-herdr-bridge) 0.4.0 from a
commit- and hash-pinned Nix store source through its generated `--patch` layer.
There is no runtime npm installation. The patch specifies the Nix-provided
Herdr Core executable and groups sessions by folder in Herdr App.

The bridge uses UM790-Pro's local Herdr Core. Sessions appear on their first
run, or when `/herdr` is entered in a Web session. On UM790-Pro, `hc templates`
lists `dsh`; `hc run --bg --name task dsh "…"` starts a session and
`hc send task "…"` sends a follow-up. Approval answers use `hc send --force`.

The plugin owns its writable runtime files in `~/.dsh/herdr-bridge/`, including
`bridge.log`, `control.sock`, and the `bin/dsh-hc` launcher. It also maintains
`~/.config/herdr-core/templates/dsh.md`, the DSH entry in Herdr App's
`programs.json`, and `icons/dsh-herdr-bridge.svg`. These generated files are not
Home Manager symlinks; existing custom template/program entries are preserved
by upstream. Authentication remains in DSH's existing private state.

After activation, check `systemctl --user status dsh-web`,
`tail ~/.dsh/herdr-bridge/bridge.log`, and `hc templates`. To list sessions,
run `~/.dsh/herdr-bridge/bin/dsh-hc ls`.

With DSH 0.2.2-rc.3, a graceful Web service restart closes existing bridge
terminals (the Host emits a session-disposed event). After restarting, reopen
the session with `/herdr` or `hc run --bg --name task
~/.dsh/herdr-bridge/bin/dsh-hc attach <session-id>`. The upstream 30-second
reconnect grace handles connection loss, but does not override an explicit
session-close event. Reopen terminals after upgrading the bridge as well so
they use its new proxy. Disabling the option stops loading the bridge but does not delete its generated files or session history.
