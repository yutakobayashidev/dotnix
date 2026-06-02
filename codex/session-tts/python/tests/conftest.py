from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def core_module():
    import importlib.util

    root = Path(__file__).resolve().parent.parent
    spec = importlib.util.spec_from_file_location(
        "session_tts.core",
        root / "src" / "session_tts" / "core.py",
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod
