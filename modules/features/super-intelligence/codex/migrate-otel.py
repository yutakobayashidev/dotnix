"""Replace only managed exporter enums in Codex's mutable user configuration."""

import json
import os
from pathlib import Path
import sys
import tempfile

import tomlkit


def migrate(path: Path, exporters: dict) -> None:
    if not path.exists():
        return
    # Preserve a user-managed symlink rather than silently replacing it.
    path = path.resolve()
    original = path.read_text()
    config = tomlkit.parse(original)
    if "otel" not in config:
        config["otel"] = tomlkit.table()
    for name, value in exporters.items():
        config["otel"][name] = value
    updated = tomlkit.dumps(config)
    if updated == original:
        return
    # Configuration may contain credentials: the temporary file stays in the
    # private config directory, with mode 0600, never in /tmp.
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", dir=path.parent, prefix=".codex-otel-", delete=False
        ) as stream:
            temporary = Path(stream.name)
            stream.write(updated)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    migrate(Path(sys.argv[1]), json.loads(Path(sys.argv[2]).read_text()))
