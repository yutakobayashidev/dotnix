# LiteLLM model registry

B450M-Pro4 serves <https://litellm.home.yutakobayashi.com/>. Its declarative
model registry lives in `systems/nixos/services/litellm/default.nix`.

## Model sources

- ChatGPT models use the native `chatgpt/` provider and the Responses API.
  The list was checked against the existing LiteLLM account's Codex model
  catalog on 2026-11-07. It includes GPT-6.1 Sol/Terra, GPT-6 Astra/Sol/Luna,
  and GPT-5.6 Sol/Terra/Luna. Hidden internal models are excluded.
- OpenCode Go retains the existing DeepSeek, GLM, HY, Kimi, MiMo, MiniMax, and
  Qwen families. IDs and context limits come from the
  [public Go model catalog](https://opencode.ai/inference/go/v1/models).
  Models absent from that catalog are removed instead of preserving old aliases.
  The endpoint is `https://opencode.ai/inference/go/openai/v1`; Go supports
  [translation between text API formats](https://opencode.ai/docs/console/go/#endpoints).

`deepseek-analyst` maps to `deepseek-v4-pro`; `deepseek-inbox` maps to
`deepseek-v4.1-flash`. Fallbacks use the current DeepSeek IDs and
`chatgpt/gpt-6.1-sol` or `chatgpt/gpt-6-astra`.

For Go model groups, LiteLLM's standard client-header forwarding preserves
`x-opencode-session`. The client must supply a stable ID per conversation;
the proxy does not invent a constant shared session ID. Header forwarding is
scoped to these groups, and LiteLLM excludes client authorization headers.
See [LiteLLM's forwarding behavior](https://docs.litellm.ai/docs/proxy/forward_client_headers).

## Verification and credentials

`GET /v1/models` reports configured models, not account authorization. Verify
actual requests as well. Responses requests to this ChatGPT backend need an
array of input messages; a bare input string was rejected by the backend.
The existing LiteLLM 1.106.4 library and ChatGPT credentials successfully generated
an `OK` response from `chatgpt/gpt-6-luna` during validation on 2026-11-07.

The expired OpenCode key was replaced on 2026-11-07 with a service-account key
from the Go workspace. A direct `deepseek-v4.1-flash` request returned `OK`,
`usage.opencode.billing_source: go`, and `usage.cost: 0`. Service-account keys
can use the personal Go plan; select the Go endpoint, not the pay-as-you-go
endpoint. Verify the billing source on every credential/routing change.

For future rotation, create a replacement in OpenCode Console and update the
encrypted `litellm/opencode-go-key` entry in
`systems/nixos/services/litellm/secrets.yaml`, then deploy through Comin and
restart LiteLLM and the UM790 user service `dsh-web` to reload their environments.
Never put plaintext credentials in Git, the Nix store, or temporary files.

ChatGPT refresh state remains in `/var/lib/litellm/chatgpt/auth.json`. The
sops-managed seed is installed only when that file is absent; model updates do
not overwrite an existing login. dsh's native providers are configured separately;
see [dsh web](dsh-web.md).
