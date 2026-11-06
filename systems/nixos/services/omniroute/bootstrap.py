"""Reconcile dotnix-owned OmniRoute providers, model aliases, and fallback combos."""

import json
import os
from pathlib import Path
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


class BootstrapError(Exception):
    pass


class API:
    def request(self, method, path, payload=None, timeout=30):
        request = Request(
            "http://127.0.0.1:8317" + path,
            data=None if payload is None else json.dumps(payload).encode(),
            headers={"Authorization": "Bearer sk-proxy", "Content-Type": "application/json"},
            method=method,
        )
        try:
            with urlopen(request, timeout=timeout) as response:
                return json.load(response)
        except HTTPError as error:
            raise BootstrapError(f"{method} {path}: HTTP {error.code}") from None
        except (URLError, TimeoutError, OSError, ValueError):
            # Response bodies may contain upstream credentials; never log them.
            raise BootstrapError(f"{method} {path}: request failed") from None


def wait_ready(api, deadline_seconds=120):
    deadline = time.monotonic() + deadline_seconds
    while time.monotonic() < deadline:
        try:
            remaining = deadline - time.monotonic()
            if api.request("GET", "/api/health/ping", timeout=min(5, remaining))["status"] == "ok":
                return
        except BootstrapError:
            pass
        time.sleep(min(2, max(0, deadline - time.monotonic())))
    raise BootstrapError("OmniRoute readiness timed out")


def reconcile(api, config, credentials, legacy_auth=Path("/var/lib/litellm/chatgpt/auth.json")):
    connections = api.request("GET", "/api/providers")["connections"]
    opencode = next(
        (c for c in connections if c["provider"] == "opencode-go" and c["name"] == "dotnix-opencode-go"),
        None,
    )
    provider = {
        "name": "dotnix-opencode-go",
        "apiKey": (credentials / "opencode-go-key").read_text().strip(),
    }
    if opencode:
        api.request("PUT", "/api/providers/" + quote(opencode["id"], safe=""), provider)
    else:
        api.request("POST", "/api/providers", {"provider": "opencode-go", **provider})

    # OmniRoute owns refreshed tokens after initial import. Reimporting the
    # encrypted seed on restart would overwrite the newly rotated credentials.
    if not any(c["provider"] == "codex" for c in connections):
        auth_path = legacy_auth if legacy_auth.is_file() else credentials / "chatgpt-auth.json"
        auth = json.loads(auth_path.read_text())
        result = api.request("POST", "/api/oauth/codex/import", {"accounts": auth}, timeout=60)
        if result.get("success") is not True or result.get("failed") != 0 or result.get("imported", 0) < 1:
            raise BootstrapError("POST /api/oauth/codex/import: account import failed")

    # Prefer the upstream catalog's protocol/capability metadata. Only register
    # configured legacy names absent from that catalog as manual models.
    catalog = api.request("GET", "/api/models?all=true")["models"]
    known = {(m["provider"], m["model"]) for m in catalog}
    models = [("opencode-go", m["id"], m) for m in config["opencodeModels"]]
    models += [("codex", model, {}) for model in config["chatgptModels"]]
    for provider_id, model_id, metadata in models:
        catalog_provider = "cx" if provider_id == "codex" else provider_id
        if (provider_id, model_id) not in known and (catalog_provider, model_id) not in known:
            model = {
                "provider": provider_id,
                "modelId": model_id,
                "modelName": model_id,
                "source": "manual",
                "apiFormat": "responses" if provider_id == "codex" else "chat-completions",
                "targetFormat": "openai-responses" if provider_id == "codex" else metadata.get("targetFormat", "openai"),
            }
            if "context" in metadata:
                model["max_input_tokens"] = metadata["context"]
            api.request("POST", "/api/provider-models", model)
        alias = "chatgpt/" + model_id if provider_id == "codex" else model_id
        api.request("PUT", "/api/models/alias", {"alias": alias, "model": provider_id + "/" + model_id})

    combos = {c["name"]: c["id"] for c in api.request("GET", "/api/combos")["combos"]}
    for name, models in config["combos"].items():
        combo = {"name": name, "models": models, "strategy": "priority"}
        if name in combos:
            api.request("PUT", "/api/combos/" + quote(combos[name], safe=""), combo)
        else:
            api.request("POST", "/api/combos", combo)


def main():
    try:
        config = json.loads(Path(sys.argv[1]).read_text())
        credentials = Path(os.environ["CREDENTIALS_DIRECTORY"])
        api = API()
        wait_ready(api)
        reconcile(api, config, credentials)
    except BootstrapError as error:
        print(f"OmniRoute bootstrap: {error}", file=sys.stderr)
        return 1
    except (OSError, ValueError, KeyError, TypeError, IndexError):
        print("OmniRoute bootstrap: invalid configuration, credentials, or API response", file=sys.stderr)
        return 1
    print("OmniRoute providers, aliases, and combos reconciled")
    return 0


if __name__ == "__main__":
    sys.exit(main())
