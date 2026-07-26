import os


def test_configured_data_dir(core_module, monkeypatch):
    monkeypatch.setenv("SESSION_TTS_HOME", "/tmp/custom-session-tts")
    assert core_module.resolve_data_dir() == "/tmp/custom-session-tts"


def test_xdg_state_data_dir(core_module, monkeypatch):
    monkeypatch.delenv("SESSION_TTS_HOME", raising=False)
    monkeypatch.setenv("XDG_STATE_HOME", "/tmp/state")
    assert core_module.resolve_data_dir() == "/tmp/state/session-tts"


def test_default_data_dir(core_module, monkeypatch):
    monkeypatch.delenv("SESSION_TTS_HOME", raising=False)
    monkeypatch.delenv("XDG_STATE_HOME", raising=False)
    monkeypatch.setenv("HOME", "/tmp/home")
    assert core_module.resolve_data_dir() == "/tmp/home/.local/state/session-tts"


def test_player_worker_uses_configured_player(core_module, monkeypatch, tmp_path):
    wav = tmp_path / "speech.wav"
    wav.write_bytes(b"wav")
    calls = []

    monkeypatch.setattr(core_module, "PLAYER", "/nix/store/player/bin/pw-play")
    monkeypatch.setattr(core_module, "resolve_playback_volume", lambda: "0.80")
    monkeypatch.setattr(
        core_module.subprocess,
        "run",
        lambda argv, check: calls.append((argv, check)),
    )

    play_queue = core_module.queue.Queue()
    play_queue.put(os.fspath(wav))
    play_queue.put(None)
    core_module.player_worker(play_queue)

    assert calls == [
        (["/nix/store/player/bin/pw-play", "--volume", "0.80", os.fspath(wav)], False)
    ]
    assert not wav.exists()
