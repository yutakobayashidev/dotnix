"""Run under dbus-run-session with pygobject3 and dbus-next installed."""

import asyncio
import json
import os
from pathlib import Path
import signal
import sys
import tempfile
import unittest

from dbus_next import Variant
from dbus_next.aio import MessageBus
from dbus_next.constants import PropertyAccess
from dbus_next.service import ServiceInterface, dbus_property


class Player(ServiceInterface):
    def __init__(self):
        super().__init__("org.mpris.MediaPlayer2.Player")
        self.status = "Playing"
        self.position = 0

    @dbus_property(access=PropertyAccess.READ)
    def PlaybackStatus(self) -> "s":
        return self.status

    @dbus_property(access=PropertyAccess.READ)
    def Position(self) -> "x":
        return self.position

    @dbus_property(access=PropertyAccess.READ)
    def Rate(self) -> "d":
        return 1.0

    @dbus_property(access=PropertyAccess.READ)
    def Metadata(self) -> "a{sv}":
        return {
            "mpris:trackid": Variant("o", "/track/test"),
            "xesam:title": Variant("s", "テスト動画"),
            "mpris:length": Variant("x", 30_000_000),
        }

    def change(self, status, position):
        self.status = status
        self.position = position
        self.emit_properties_changed({"PlaybackStatus": status})


class DBusTest(unittest.TestCase):
    def test_real_dbus_pause_resume_stop_and_proxy_exclusion(self):
        asyncio.run(self.exercise())

    async def exercise(self):
        bus = await MessageBus().connect()
        player = Player()
        bus.export("/org/mpris/MediaPlayer2", player)
        await bus.request_name("org.mpris.MediaPlayer2.fixture")
        await bus.request_name("org.mpris.MediaPlayer2.playerctld")
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "plays.jsonl"
            command = (
                [os.environ["MPRIS_LOGGER"]]
                if "MPRIS_LOGGER" in os.environ
                else [sys.executable, str(Path(__file__).with_name("collector.py"))]
            )
            proc = await asyncio.create_subprocess_exec(
                *command,
                "--device",
                "fixture-device",
                "--output",
                str(output),
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            try:
                await asyncio.sleep(1)
                player.change("Paused", 1_000_000)
                await asyncio.sleep(1)
                player.change("Playing", 1_000_000)
                await asyncio.sleep(1)
                player.change("Stopped", 2_000_000)
                await asyncio.sleep(0.5)
                if proc.returncode is None:
                    proc.send_signal(signal.SIGTERM)
                _, err = await asyncio.wait_for(proc.communicate(), 5)
                self.assertEqual(proc.returncode, 0, err.decode())
                rows = [json.loads(line) for line in output.read_text().splitlines()]
                self.assertEqual(len(rows), 1)
                self.assertEqual(rows[0]["player"], "fixture")
                self.assertEqual(rows[0]["title"], "テスト動画")
                self.assertEqual(rows[0]["played_secs"], 2)
                self.assertEqual(rows[0]["seek_count"], 0)
            finally:
                if proc.returncode is None:
                    proc.kill()
                    await proc.communicate()
                bus.disconnect()
                await bus.wait_for_disconnect()


if __name__ == "__main__":
    unittest.main()
