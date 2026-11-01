"""Exercise provisioning contracts without real credentials or upstream requests."""

import copy
import io
from pathlib import Path
import unittest
from unittest.mock import patch
from urllib.error import HTTPError

import bootstrap


CONFIG = {
    "opencodeModels": [{"id": "deepseek-v4-pro", "context": 1048576}],
    "chatgptModels": ["gpt-5.4"],
    "combos": {"deepseek-analyst": ["opencode-go/deepseek-v4-pro", "codex/gpt-5.4"]},
}


class FakeAPI:
    def __init__(self):
        self.connections = []
        self.aliases = {}
        self.combos = []
        self.calls = []
        self.catalog = [{"provider": "opencode-go", "model": "deepseek-v4-pro"}]
        self.import_result = {"success": True, "imported": 1, "failed": 0}

    def request(self, method, path, payload=None, timeout=30):
        self.calls.append((method, path, copy.deepcopy(payload)))
        if (method, path) == ("GET", "/api/health/ping"):
            return {"status": "ok"}
        if (method, path) == ("GET", "/api/providers"):
            return {"connections": copy.deepcopy(self.connections)}
        if (method, path) == ("POST", "/api/providers"):
            self.connections.append({"id": "opencode-id", **payload})
            return {"connection": self.connections[-1]}
        if (method, path) == ("PUT", "/api/providers/opencode-id"):
            self.connections[0].update(payload)
            return {"connection": self.connections[0]}
        if (method, path) == ("POST", "/api/oauth/codex/import"):
            if self.import_result["success"]:
                self.connections.append({"id": "codex-id", "provider": "codex", "name": "Imported"})
            return self.import_result
        if (method, path) == ("GET", "/api/models?all=true"):
            return {"models": self.catalog}
        if (method, path) == ("POST", "/api/provider-models"):
            self.catalog.append({"provider": payload["provider"], "model": payload["modelId"]})
            return {"model": payload}
        if (method, path) == ("PUT", "/api/models/alias"):
            self.aliases[payload["alias"]] = payload["model"]
            return {"success": True}
        if (method, path) == ("GET", "/api/combos"):
            return {"combos": copy.deepcopy(self.combos)}
        if (method, path) == ("POST", "/api/combos"):
            self.combos.append({"id": "combo-id", **payload})
            return self.combos[-1]
        if (method, path) == ("PUT", "/api/combos/combo-id"):
            self.combos[0].update(payload)
            return self.combos[0]
        raise AssertionError(f"Unexpected API request: {method} {path}")


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.api = FakeAPI()
        self.reads = []

        def read(path):
            self.reads.append(str(path))
            if path.name == "opencode-go-key":
                return "test-provider-key\n"
            if str(path) == "/legacy/auth.json":
                return '{"tokens":{"refresh_token":"test-live-token"}}'
            if path.name == "chatgpt-auth.json":
                return '{"tokens":{"refresh_token":"test-seed-token"}}'
            raise AssertionError(f"Unexpected file read: {path}")

        self.patcher = patch.object(Path, "read_text", read)
        self.patcher.start()
        self.addCleanup(self.patcher.stop)

    def run_reconcile(self, config=CONFIG, live=False):
        with patch.object(Path, "is_file", return_value=live):
            bootstrap.reconcile(self.api, config, Path("/credentials"), Path("/legacy/auth.json"))

    def test_initial_setup_preserves_names_and_protocols(self):
        self.run_reconcile()
        self.assertEqual(self.api.aliases["deepseek-v4-pro"], "opencode-go/deepseek-v4-pro")
        self.assertEqual(self.api.aliases["chatgpt/gpt-5.4"], "codex/gpt-5.4")
        self.assertEqual(self.api.combos[0]["models"], CONFIG["combos"]["deepseek-analyst"])
        self.assertEqual(self.api.combos[0]["strategy"], "priority")
        registrations = [body for method, path, body in self.api.calls if path == "/api/provider-models"]
        self.assertEqual(len(registrations), 1)  # Existing native model metadata is left intact.
        self.assertEqual(registrations[0]["apiFormat"], "responses")
        self.assertEqual(registrations[0]["targetFormat"], "openai-responses")

    def test_restarts_update_configuration_without_reimporting_tokens(self):
        self.run_reconcile()
        self.reads.clear()
        changed = copy.deepcopy(CONFIG)
        changed["combos"]["deepseek-analyst"].reverse()
        self.run_reconcile(changed)
        imports = [c for c in self.api.calls if c[1] == "/api/oauth/codex/import"]
        self.assertEqual(len(imports), 1)
        self.assertEqual(self.reads, ["/credentials/opencode-go-key"])
        self.assertEqual(len(self.api.connections), 2)
        self.assertEqual(len(self.api.combos), 1)
        self.assertEqual(self.api.combos[0]["models"], changed["combos"]["deepseek-analyst"])
        self.assertIn(("PUT", "/api/providers/opencode-id", {"name": "dotnix-opencode-go", "apiKey": "test-provider-key"}), self.api.calls)

    def test_prefers_live_litellm_tokens_over_encrypted_seed(self):
        self.run_reconcile(live=True)
        imported = next(body for _, path, body in self.api.calls if path == "/api/oauth/codex/import")
        self.assertEqual(imported["accounts"]["tokens"]["refresh_token"], "test-live-token")
        self.assertNotIn("/credentials/chatgpt-auth.json", self.reads)

    def test_http_success_with_failed_import_stops_provisioning(self):
        self.api.import_result = {"success": False, "imported": 0, "failed": 1, "results": [{"error": "sensitive"}]}
        with self.assertRaisesRegex(bootstrap.BootstrapError, "account import failed") as error:
            self.run_reconcile()
        self.assertNotIn("sensitive", str(error.exception))
        self.assertFalse(self.api.aliases)

    def test_health_retry_is_bounded(self):
        with patch.object(bootstrap.time, "monotonic", side_effect=[0, 0, 1, 120, 120]), patch.object(bootstrap.time, "sleep"), patch.object(self.api, "request", side_effect=bootstrap.BootstrapError("unavailable")):
            with self.assertRaisesRegex(bootstrap.BootstrapError, "readiness timed out"):
                bootstrap.wait_ready(self.api)

    def test_http_errors_do_not_leak_response_bodies(self):
        error = HTTPError("http://127.0.0.1:8317/api/providers", 400, "secret-value", {}, io.BytesIO(b"secret-value"))
        with patch.object(bootstrap, "urlopen", side_effect=error):
            with self.assertRaisesRegex(bootstrap.BootstrapError, "HTTP 400") as result:
                bootstrap.API().request("POST", "/api/providers", {"apiKey": "secret-value"})
        self.assertNotIn("secret-value", str(result.exception))


if __name__ == "__main__":
    unittest.main()
