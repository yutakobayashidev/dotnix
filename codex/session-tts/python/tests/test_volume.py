def test_missing_file_returns_default(core_module, tmp_path):
    core_module.VOLUME_FILE = str(tmp_path / "nonexistent")
    assert core_module.resolve_playback_volume() == "0.80"


def test_valid_value(core_module, tmp_path):
    f = tmp_path / "volume"
    f.write_text("0.5")
    core_module.VOLUME_FILE = str(f)
    assert core_module.resolve_playback_volume() == "0.50"


def test_whitespace_handling(core_module, tmp_path):
    f = tmp_path / "volume"
    f.write_text("  0.75  ")
    core_module.VOLUME_FILE = str(f)
    assert core_module.resolve_playback_volume() == "0.75"


def test_boundary_values(core_module, tmp_path):
    f = tmp_path / "volume"
    for v in (0.0, 1.0):
        f.write_text(str(v))
        core_module.VOLUME_FILE = str(f)
        assert core_module.resolve_playback_volume() == f"{v:.2f}"


def test_out_of_range_falls_back(core_module, tmp_path):
    f = tmp_path / "volume"
    f.write_text("1.5")
    core_module.VOLUME_FILE = str(f)
    assert core_module.resolve_playback_volume() == "0.80"


def test_negative_falls_back(core_module, tmp_path):
    f = tmp_path / "volume"
    f.write_text("-0.1")
    core_module.VOLUME_FILE = str(f)
    assert core_module.resolve_playback_volume() == "0.80"


def test_unparseable_falls_back(core_module, tmp_path):
    f = tmp_path / "volume"
    f.write_text("loud")
    core_module.VOLUME_FILE = str(f)
    assert core_module.resolve_playback_volume() == "0.80"


def test_empty_file_falls_back(core_module, tmp_path):
    f = tmp_path / "volume"
    f.write_text("")
    core_module.VOLUME_FILE = str(f)
    assert core_module.resolve_playback_volume() == "0.80"
