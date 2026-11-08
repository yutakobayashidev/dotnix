# OmniRoute migration

OmniRoute 3.8.53 uses the package and NixOS module from nixpkgs PR #548454,
pinned by `omniroute-nixpkgs` in `flake.nix` and `flake.lock`. The feature in
`modules/features/super-intelligence/omniroute/` imports that module and builds
the package against dotnix's nixpkgs. A local build adjustment limits Next.js
page-data workers to two; the unmodified build failed with fifteen workers on
UM790-Pro.

## Service and clients

`systems/nixos/services/omniroute/default.nix` enables a loopback-only server on
B450M-Pro4 at port 20128. The host imports this service instead of LiteLLM.
Traefik keeps `https://litellm.home.yutakobayashi.com` and forwards it to
OmniRoute, so existing clients retain their base URL, key, and model names.
These changes take effect when the NixOS configuration is activated.

Service data is stored in `/var/lib/omniroute` under the upstream module's
dynamic system user. API keys are required. `OMNIROUTE_API_KEY` temporarily
preserves LiteLLM's existing `sk-proxy` master/client key; OmniRoute gives this
environment key management permissions as well as inference access.

The initial dashboard password is stored encrypted in
`systems/nixos/services/omniroute/secrets.env` and supplied by sops-nix. Its
recovery copy is `/var/lib/omniroute-credentials/environment` on B450M-Pro4,
owned by root with mode 0600 in a 0700 directory. The password is only an
initial seed; later dashboard password changes live in OmniRoute's database.
Do not print either credential source or copy plaintext into the repository
or a temporary directory.

## Import and verification

The PR's `settings` option configures environment variables, not a declarative
provider/model registry. Use OmniRoute's supported management APIs for the
one-time data migration; no periodic reconciliation service is installed.

Run `systems/nixos/services/omniroute/migrate-from-litellm.py` as root on B450M
after starting OmniRoute. It reads the current ChatGPT login from
`/var/lib/litellm/chatgpt/auth.json` and the Go key from
`/run/secrets/litellm/opencode-go-key`, passes them over loopback to the import
APIs, and preserves existing model aliases and the two Birdclaw priority
fallback combos. Exact-name combos for the ordinary model names preserve
LiteLLM's default fallback order, with duplicate targets removed. Provider-qualified
targets inside each combo avoid recursive combo routing.
It skips connections/combos it already created. It does not
delete LiteLLM state or enable cloud synchronization.

Before switching the reverse proxy, verify:

1. Requests without a key are rejected by the inference endpoints.
2. `deepseek-v4.1-flash` chat completion works with the existing client key and
   reports Go subscription billing rather than pay-as-you-go billing.
3. `chatgpt/gpt-6-luna` Responses requests work, including streamed responses.
4. `deepseek-analyst` and `deepseek-inbox` route correctly, and client
   `x-opencode-session` headers survive the Go path.

### Verification on B450M-Pro4, 2026-11-09

The package built on UM790-Pro and its runtime closure was copied directly to
B450M-Pro4. A transient `omniroute-staging` service used the production data
directory, loopback binding, API-key requirement, and systemd isolation.
The import created two provider connections and 28 priority combos.

- `/api/health`: 200; inference without a key: 401.
- Go direct provider target and the existing `deepseek-v4.1-flash` name: 200.
- `deepseek-inbox`: returned `deepseek-v4.1-flash`; `deepseek-analyst`: returned
  `deepseek-v4-pro`.
- `chatgpt/gpt-6-luna` Responses: 200, including a completed SSE response.
- The same Go key against OmniRoute's upstream `/zen/go/v1/chat/completions`,
  using its OpenCode header format, returned `usage.opencode.billing_source=go`
  and `usage.cost=0`. OmniRoute's normalized usage omits the `opencode` metadata,
  so this billing check was made directly against that upstream.

Upstream source inspection confirms forwarding of `x-opencode-session`.
OmniRoute normalizes noncanonical session identifiers to OpenCode's format;
it preserves conversation affinity rather than promising byte-for-byte identity.
Failure injection across every fallback and every registered model was not tested.

Avoid running two independent refreshers against the same ChatGPT refresh
token during cutover. Keep the old state for rollback, but stop LiteLLM when
OmniRoute becomes the active backend. The Go credential file must remain
available to dsh on UM790-Pro even after LiteLLM is retired.

## Deployment and rollback

Stop the transient `omniroute-staging` unit after testing so it does not occupy
port 20128 when the managed service starts. Deploy through the repository's
normal Comin workflow. Verify the public `/v1` endpoints after activation.

To roll back, change the B450M service import from `omniroute` to `litellm`
and deploy that revision. Keep `/var/lib/omniroute`, the old LiteLLM state, and
the encrypted LiteLLM files. ChatGPT refresh tokens may rotate after cutover:
re-authenticate LiteLLM if its retained token is stale rather than assuming
the original login is still valid. Never run both backends' refreshers long term.

## References

- [nixpkgs PR #548454](https://github.com/NixOS/nixpkgs/pull/548454)
- [Pinned environment reference](https://github.com/cheaper-inference/OmniRoute/blob/v3.8.53/docs/reference/ENVIRONMENT.md)
- [Existing LiteLLM registry and consumers](litellm.md)
