"""One-time local API migration; run as root on B450M after starting OmniRoute.

Credentials stay in memory. This is an explicit migration, not a boot service.
The existing LiteLLM state and its sops files remain available for rollback.
"""

import json
from pathlib import Path
import urllib.error
import urllib.request


BASE = "http://127.0.0.1:20128"
GO_MODELS = [
    "deepseek-v4-pro",
    "deepseek-v4.1-flash",
    "glm-5.2",
    "glm-5.3",
    "glm-5.3-flash",
    "hy3",
    "hy4",
    "hy4-preview",
    "kimi-k2.7-code",
    "kimi-k3",
    "kimi-k3.1-pro",
    "mimo-v2.6-flash",
    "mimo-v2.6-pro",
    "minimax-m3",
    "minimax-m3.1-flash",
    "qwen3.7-plus",
    "qwen3.8-flash",
    "qwen3.8-max",
]
CHATGPT_MODELS = [
    "gpt-6.1-sol",
    "gpt-6.1-terra",
    "gpt-6-astra",
    "gpt-6-sol",
    "gpt-6-luna",
    "gpt-5.6-sol",
    "gpt-5.6-terra",
    "gpt-5.6-luna",
]


def api(method, path, body=None):
    data = None if body is None else json.dumps(body).encode()
    request = urllib.request.Request(
        BASE + path,
        data=data,
        method=method,
        headers={
            "Authorization": "Bearer sk-proxy",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        # Response bodies can contain credentials; never print them.
        raise SystemExit(f"{method} {path}: HTTP {error.code}") from None


def main():
    connections = api("GET", "/api/providers")["connections"]
    if not any(c.get("name") == "LiteLLM ChatGPT migration" for c in connections):
        auth = json.loads(Path("/var/lib/litellm/chatgpt/auth.json").read_text())
        api(
            "POST",
            "/api/providers/codex-auth/import",
            {
                "source": {"kind": "json", "json": auth},
                "name": "LiteLLM ChatGPT migration",
                "overwriteExisting": False,
            },
        )
        print("ChatGPT credentials imported.")

    if not any(c.get("name") == "LiteLLM OpenCode Go migration" for c in connections):
        key = Path("/run/secrets/litellm/opencode-go-key").read_text().strip()
        api(
            "POST",
            "/api/providers",
            {
                "provider": "opencode-go",
                "name": "LiteLLM OpenCode Go migration",
                "apiKey": key,
            },
        )
        print("OpenCode Go credentials imported.")

    # Use the publication API so aliases appear in /v1/models as well as route.
    for model in GO_MODELS:
        api(
            "PUT",
            "/api/models/alias",
            {"alias": model, "model": f"opencode-go/{model}"},
        )
    for model in CHATGPT_MODELS:
        api(
            "PUT",
            "/api/models/alias",
            {"alias": f"chatgpt/{model}", "model": f"codex/{model}"},
        )

    existing = {c["name"] for c in api("GET", "/api/combos")["combos"]}
    combos = {
        "deepseek-analyst": [
            "opencode-go/deepseek-v4-pro",
            "opencode-go/deepseek-v4.1-flash",
            "codex/gpt-6.1-sol",
        ],
        "deepseek-inbox": [
            "opencode-go/deepseek-v4.1-flash",
            "opencode-go/deepseek-v4-pro",
            "codex/gpt-6-astra",
        ],
    }
    # LiteLLM also applied default_fallbacks to ordinary model requests.
    # Exact-name combos preserve that behavior; qualified targets inside each
    # combo go straight to their provider and do not recurse into the combo.
    defaults = [
        "opencode-go/deepseek-v4-pro",
        "opencode-go/deepseek-v4.1-flash",
        "codex/gpt-6.1-sol",
    ]
    primary_models = {model: f"opencode-go/{model}" for model in GO_MODELS}
    primary_models.update(
        {f"chatgpt/{model}": f"codex/{model}" for model in CHATGPT_MODELS}
    )
    for name, primary in primary_models.items():
        combos[name] = list(dict.fromkeys([primary, *defaults]))
    for name, models in combos.items():
        if name not in existing:
            api(
                "POST",
                "/api/combos",
                {"name": name, "models": models, "strategy": "priority"},
            )
    print(
        "Model aliases and Birdclaw fallback combos imported; inference must be verified before cutover."
    )


if __name__ == "__main__":
    main()
