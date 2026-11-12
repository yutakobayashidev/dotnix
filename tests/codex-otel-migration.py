"""Run with the same tomlkit-enabled Python used by the activation hook."""

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

import tomlkit

script = (
    Path(__file__).resolve().parents[1]
    / "modules/features/super-intelligence/codex/migrate-otel.py"
)
spec = importlib.util.spec_from_file_location("migration", script)
migration = importlib.util.module_from_spec(spec)
spec.loader.exec_module(migration)


class MigrationTest(unittest.TestCase):
    def test_replaces_exporter_variants_preserves_settings_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.toml"
            path.write_text("""# personal preferences
model = "example-model"
[otel]
environment = "home-test"
log_user_prompt = false
[otel.exporter.otlp-http]
endpoint = "http://old/v1/logs"
[otel.metrics_exporter.otlp-http]
endpoint = "http://old/v1/metrics"
[otel.trace_exporter.otlp-http]
endpoint = "http://old/v1/traces"
[mcp_servers.example]
command = "example"
""")
            exporters = {
                name: {"otlp-grpc": {"endpoint": "http://127.0.0.1:4317"}}
                for name in ["exporter", "metrics_exporter", "trace_exporter"]
            }
            migration.migrate(path, exporters)
            first = path.read_text()
            config = tomlkit.parse(first)
            for name, value in exporters.items():
                self.assertEqual(config["otel"][name].unwrap(), value)
            self.assertEqual(config["model"], "example-model")
            self.assertEqual(config["otel"]["environment"], "home-test")
            self.assertEqual(config["mcp_servers"]["example"]["command"], "example")
            self.assertIn("# personal preferences", first)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            migration.migrate(path, exporters)
            self.assertEqual(path.read_text(), first)
            migration.migrate(path, {name: "none" for name in exporters})
            self.assertTrue(
                all(
                    tomlkit.parse(path.read_text())["otel"][name] == "none"
                    for name in exporters
                )
            )
            self.assertEqual(list(Path(directory).iterdir()), [path])

    def test_missing_file_is_not_created(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.toml"
            migration.migrate(path, {"exporter": "none"})
            self.assertFalse(path.exists())


if __name__ == "__main__":
    unittest.main()
