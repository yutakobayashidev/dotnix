"""Read four Discord webhooks without echo and encrypt them directly with sops."""

import getpass
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[4]
CHANNELS = ("infra-critical", "infra-warning", "infra-info", "home")


def main():
    if not sys.stdin.isatty():
        raise SystemExit("Run this command in an interactive terminal.")
    sops = shutil.which("sops")
    if not sops:
        raise SystemExit(
            "sops is required; run using the command in docs/monitoring.md."
        )

    destination = ROOT / "secrets/alertmanager.yaml"
    if destination.exists():
        answer = input("Replace all four stored webhook URLs? [y/N] ")
        if answer.lower() != "y":
            raise SystemExit("Cancelled; no changes made.")

    webhooks = {}
    for channel in CHANNELS:
        value = getpass.getpass(f"Discord #{channel} webhook URL: ").strip()
        if not re.fullmatch(
            r"https://discord\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]+", value
        ):
            raise SystemExit(
                f"Invalid Discord webhook URL for {channel}; no changes made."
            )
        webhooks[f"discord-{channel}"] = value

    # Plaintext goes only through a pipe; neither argv nor a temporary file.
    result = subprocess.run(
        [
            sops,
            "encrypt",
            "--filename-override",
            "secrets/alertmanager.yaml",
            "--input-type",
            "json",
            "--output-type",
            "yaml",
            "/dev/stdin",
        ],
        input=json.dumps(webhooks).encode(),
        capture_output=True,
        cwd=ROOT,
    )
    if result.returncode:
        raise SystemExit("sops encryption failed; existing secrets were not changed.")

    # The staging file contains ciphertext only. Rename atomically on success.
    staging = destination.with_suffix(".yaml.new")
    fd = os.open(staging, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(result.stdout)
        staging.replace(destination)
    finally:
        staging.unlink(missing_ok=True)
    print("Saved encrypted webhooks to secrets/alertmanager.yaml. No messages sent.")


if __name__ == "__main__":
    main()
