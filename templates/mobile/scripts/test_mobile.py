"""Exercise device targeting, timeouts and evidence preservation without an emulator."""

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPT = str(Path(sys.argv.pop(1)).resolve())


class MobileTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "calls"
        self.env = dict(
            os.environ,
            MOBILE_WORKSPACE=str(self.root),
            ANDROID_HOME="/sdk",
            ANDROID_AVD_HOME=str(self.root / "avd"),
            MOBILE_AVD="analysis-36",
            MOBILE_PORT="5556",
            MOBILE_IMAGE="system-images;android-36;default;x86_64",
            MOBILE_ANALYSIS="1",
            MOBILE_EMULATOR="1",
            PATH=str(self.bin) + ":" + os.environ["PATH"],
        )
        for tool in ("adb", "android", "avdmanager", "jadx", "apktool", "maestro"):
            p = self.bin / tool
            p.write_text(
                "#!"
                + shutil.which("bash")
                + '\nprintf "%s\\n" "$0" "$@" >> "'
                + str(self.log)
                + '"\n'
            )
            p.chmod(0o755)

    def run_mobile(self, *args):
        return subprocess.run(
            ["bash", SCRIPT, *args],
            env=self.env,
            cwd=self.root,
            capture_output=True,
            text=True,
            timeout=5,
        )

    def test_android_pins_sdk_and_preserves_arguments(self):
        r = self.run_mobile("android", "screen", "some argument")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(
            self.log.read_text().splitlines()[1:],
            ["--no-metrics", "--sdk=/sdk", "screen", "some argument"],
        )

    def test_create_uses_separate_writable_sdk(self):
        r = self.run_mobile("create", "--list")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(
            self.log.read_text().splitlines()[1:],
            [
                "--no-metrics",
                "--sdk=" + str(self.root / ".mobile/bootstrap-sdk"),
                "create",
                "--list",
            ],
        )

    def test_wait_is_bounded_and_targets_analysis_device(self):
        r = self.run_mobile("wait", "1")
        self.assertEqual(r.returncode, 124)
        self.assertIn("emulator-5556", self.log.read_text())

    def test_maestro_targets_current_avd_and_preserves_arguments(self):
        r = self.run_mobile(
            "test", "-e", "READY_TEXT=Hello World", ".maestro/smoke.yaml"
        )
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(
            self.log.read_text().splitlines()[1:],
            [
                "--device",
                "emulator-5556",
                "test",
                "-e",
                "READY_TEXT=Hello World",
                ".maestro/smoke.yaml",
            ],
        )

    def test_maestro_can_target_a_physical_device(self):
        self.env["MOBILE_DEVICE"] = "physical-serial"
        r = self.run_mobile("test", "flow.yaml")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(
            self.log.read_text().splitlines()[1:4],
            ["--device", "physical-serial", "test"],
        )

    def test_existing_avd_is_preserved(self):
        avd = self.root / "avd"
        avd.mkdir()
        (avd / "analysis-36.ini").write_text("existing")
        self.assertNotEqual(self.run_mobile("avd-create").returncode, 0)
        self.assertEqual((avd / "analysis-36.ini").read_text(), "existing")
        self.assertFalse(self.log.exists())

    def test_existing_analysis_output_is_preserved(self):
        apk = self.root / "input.apk"
        apk.write_bytes(b"original")
        (self.root / "report").mkdir()
        self.assertNotEqual(
            self.run_mobile("analyze", str(apk), "report").returncode, 0
        )
        self.assertFalse(self.log.exists())
        self.assertEqual(apk.read_bytes(), b"original")

    def test_analysis_records_hash_and_keeps_input(self):
        apk = self.root / "input with spaces.apk"
        apk.write_bytes(b"original")
        r = self.run_mobile("analyze", str(apk), "report")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertTrue((self.root / "report/SHA256SUMS").is_file())
        self.assertEqual(apk.read_bytes(), b"original")
        self.assertIn(str(apk), self.log.read_text())


unittest.main()
