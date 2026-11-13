"""Run composite-action pin regressions offline (Python, PyYAML, bash and jq)."""

import json
import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]
PIN = "682096be7038a86337aafa8d213aa3364d204f9f"


class FlakeUpdatePins(unittest.TestCase):
    def run_action(self, action, requested="", skip_delay="false"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            nodes = {
                "root": {"inputs": {"pinned": "pinned", "tracking": "tracking"}},
                "pinned": {
                    "original": {"owner": "NixOS", "repo": "nixpkgs", "rev": PIN},
                    "locked": {"rev": "incorrect-updater-revision"},
                },
                "tracking": {
                    "original": {
                        "owner": "NixOS",
                        "repo": "nixpkgs",
                        "ref": "nixos-unstable",
                    },
                    "locked": {"rev": "latest-tracking-revision"},
                },
            }
            (root / "flake.lock").write_text(json.dumps({"nodes": nodes}))
            (root / "metadata.json").write_text(json.dumps({"locks": {"nodes": nodes}}))
            binary = root / "bin"
            binary.mkdir()
            for name, script in {
                "nix": '#!/bin/bash\nif [[ "$1 $2" == "flake metadata" ]]; then cat metadata.json; else echo unexpected-nix-call >&2; exit 99; fi\n',
                "gh": "#!/bin/bash\necho unexpected-network-call >&2\nexit 99\n",
            }.items():
                path = binary / name
                path.write_text(
                    script.replace("#!/bin/bash", "#!" + shutil.which("bash"))
                )
                path.chmod(0o755)
            definition = yaml.safe_load(
                (ROOT / ".github/actions" / action / "action.yaml").read_text()
            )
            script = next(
                step["run"] for step in definition["runs"]["steps"] if "run" in step
            )
            output = root / "output"
            result = subprocess.run(
                ["bash", "-c", script],
                cwd=root,
                text=True,
                capture_output=True,
                env={
                    **os.environ,
                    "PATH": str(binary) + os.pathsep + os.environ["PATH"],
                    "GITHUB_OUTPUT": str(output),
                    "INPUTS": requested,
                    "EXCLUDE_INPUTS": "",
                    "SKIP_DELAY_INPUTS": "",
                    "INPUT_NAME": "pinned",
                    "INPUT_OWNER": "NixOS",
                    "INPUT_REPO": "nixpkgs",
                    "INPUT_REF": "",
                    "SKIP_DELAY": skip_delay,
                    "MIN_AGE_DAYS": "3",
                },
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertNotIn("unexpected-", result.stderr)
            return dict(line.split("=", 1) for line in output.read_text().splitlines())

    def test_discovery_preserves_branch_tracking_and_skips_explicit_revision(self):
        output = self.run_action("discover-flake-inputs")
        matrix = json.loads(output["matrix"])["include"]
        self.assertEqual([entry["name"] for entry in matrix], ["tracking"])
        self.assertEqual(matrix[0]["ref"], "nixos-unstable")

    def test_explicit_request_does_not_override_pin(self):
        output = self.run_action("discover-flake-inputs", requested="pinned")
        self.assertEqual(json.loads(output["matrix"]), {"include": []})
        self.assertEqual(output["has-updates"], "false")

    def test_update_rechecks_pin_before_api_or_lock_mutation(self):
        for skip_delay in ("false", "true"):
            with self.subTest(skip_delay=skip_delay):
                self.assertEqual(
                    self.run_action("update-flake-input", skip_delay=skip_delay)[
                        "updated"
                    ],
                    "false",
                )


if __name__ == "__main__":
    unittest.main()
