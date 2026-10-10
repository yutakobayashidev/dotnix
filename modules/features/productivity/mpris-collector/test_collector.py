import json
from pathlib import Path
import tempfile
import unittest

from collector import Journal, Tracker

NAME = "org.mpris.MediaPlayer2.firefox.instance1"


def props(position=0, status="Playing", rate=1, track="/track/1", url="", length=None):
    meta = {"mpris:trackid": track, "xesam:title": "動画", "xesam:url": url}
    if length is not None:
        meta["mpris:length"] = length * 1_000_000
    return {
        "Metadata": meta,
        "Position": None if position is None else position * 1_000_000,
        "PlaybackStatus": status,
        "Rate": rate,
    }


class TrackerTest(unittest.TestCase):
    def setUp(self):
        self.rows = []
        self.tracker = Tracker("thinkpad", self.rows.append)

    def observe(self, tick, **kwargs):
        self.tracker.observe(
            NAME,
            props(**kwargs),
            f"2026-10-11T00:{tick // 60:02}:{tick % 60:02}Z",
            tick,
        )

    def test_url_less_track_pause_resume_and_double_speed(self):
        self.observe(0, rate=2)
        self.observe(5, position=10, rate=2, status="Paused")
        self.observe(10, position=10, status="Playing")
        self.observe(15, position=15, status="Stopped")
        self.assertEqual(len(self.rows), 1)
        self.assertEqual(self.rows[0]["played_secs"], 15)
        self.assertEqual(self.rows[0]["seek_count"], 0)
        self.assertIsNone(self.rows[0]["track_secs"])
        self.assertEqual(self.rows[0]["artist"], "")

    def test_seek_and_track_switch_do_not_count_jumps(self):
        self.observe(0)
        self.observe(5, position=5)
        self.tracker.observe(
            NAME, props(position=100), "2026-10-11T00:00:06Z", 6, seek_position=100
        )
        self.observe(11, position=105)
        self.observe(12, position=0, track="/track/2")
        self.tracker.close()
        self.assertEqual(self.rows[0]["played_secs"], 10)
        self.assertEqual(self.rows[0]["seek_count"], 1)
        self.assertEqual(self.rows[0]["max_position_secs"], 105)
        self.assertNotEqual(self.rows[0]["id"], self.rows[1]["id"])

    def test_checkpoint_uses_same_id_and_suspend_splits(self):
        for tick in range(0, 66, 5):
            self.observe(tick, position=tick)
        self.assertEqual(len(self.rows), 1)
        self.assertEqual(self.rows[0]["played_secs"], 60)
        self.observe(200, position=200)
        self.tracker.close()
        self.assertEqual(self.rows[0]["id"], self.rows[1]["id"])
        self.assertEqual(self.rows[1]["played_secs"], 65)
        self.assertEqual(self.rows[1]["ended_at"], "2026-10-11T00:01:05Z")
        self.assertNotEqual(self.rows[1]["id"], self.rows[2]["id"])

    def test_missing_positions_do_not_invent_playback(self):
        self.observe(0, position=None)
        self.observe(5, position=None)
        self.observe(10, position=80)
        self.observe(15, position=85)
        self.tracker.close()
        self.assertEqual(self.rows[0]["played_secs"], 5)

    def test_simultaneous_instances_have_independent_ids(self):
        self.observe(0)
        self.tracker.observe(NAME + "2", props(), "2026-10-11T00:00:00Z", 0)
        self.tracker.close()
        self.assertEqual(len({r["id"] for r in self.rows}), 2)

    def test_poll_detects_backward_and_forward_seeks(self):
        self.observe(0, position=20)
        self.observe(5, position=100)
        self.observe(10, position=10)
        self.observe(15, position=15)
        self.tracker.close()
        self.assertEqual(self.rows[0]["played_secs"], 5)
        self.assertEqual(self.rows[0]["seek_count"], 2)

    def test_stop_reset_is_not_a_seek(self):
        self.observe(0)
        self.observe(5, position=5)
        self.observe(6, position=0, status="Stopped")
        self.assertEqual(self.rows[0]["seek_count"], 0)
        self.assertEqual(self.rows[0]["played_secs"], 5)

    def test_polled_seek_then_delayed_signal_is_counted_once(self):
        self.observe(0)
        self.observe(5, position=100)
        self.tracker.observe(
            NAME, props(position=101), "2026-10-11T00:00:06Z", 6, seek_position=100
        )
        self.observe(11, position=106)
        self.tracker.close()
        self.assertEqual(self.rows[0]["seek_count"], 1)
        self.assertEqual(self.rows[0]["played_secs"], 5)

    def test_matches_published_schema(self):
        import jsonschema

        self.observe(0)
        self.observe(5, position=5, length=100)
        self.tracker.close()
        schema = json.loads(Path(__file__).with_name("schema.json").read_text())
        jsonschema.validate(
            self.rows[0], schema, format_checker=jsonschema.FormatChecker()
        )


class JournalTest(unittest.TestCase):
    def test_utf8_partial_tail_recovery_and_exclusive_writer(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "plays.jsonl"
            path.write_bytes(b'{"id":"ok"}\n{"title":"\xe5')
            journal = Journal(path)
            with self.assertRaises(BlockingIOError):
                Journal(path)
            journal.append({"title": "日本語"})
            journal.close()
            self.assertEqual(
                [json.loads(line) for line in path.read_text().splitlines()],
                [{"id": "ok"}, {"title": "日本語"}],
            )


if __name__ == "__main__":
    unittest.main()
