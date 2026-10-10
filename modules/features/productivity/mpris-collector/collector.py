"""Local MPRIS observations, in Aurboda MediaPlayInput JSONL format."""

import argparse
import fcntl
import json
import logging
import math
import os
from pathlib import Path
import signal
import socket
import time
from datetime import datetime, timezone
from uuid import uuid4

PREFIX = "org.mpris.MediaPlayer2."
PLAYER = "org.mpris.MediaPlayer2.Player"
PROPERTIES = "org.freedesktop.DBus.Properties"
OBJECT = "/org/mpris/MediaPlayer2"
POLL_SECONDS = 5
CHECKPOINT_SECONDS = 60


def number(value):
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return float(value) if math.isfinite(value) and value >= 0 else None
    return None


def seconds(value):
    value = number(value)
    return value / 1_000_000 if value is not None else None


def timestamp():
    return datetime.now(timezone.utc).isoformat(timespec="microseconds")


def clock():
    # Includes suspend: never count an unobserved sleep interval as playback.
    return time.clock_gettime(time.CLOCK_BOOTTIME)


def text(value):
    return value if isinstance(value, str) else ""


class Tracker:
    """Pure state machine; Position measures content progression, not attention."""

    def __init__(self, device, emit):
        self.device = device
        self.emit = emit
        self.active = {}

    def finish(self, name):
        state = self.active.pop(name, None)
        if state:
            self.emit(dict(state["record"]))

    def observe(self, name, props, at, now, seek_position=None):
        meta = props.get("Metadata", {})
        title = text(meta.get("xesam:title"))
        url = text(meta.get("xesam:url"))
        artists = meta.get("xesam:artist", [])
        artist = (
            ", ".join(v for v in artists if isinstance(v, str))
            if isinstance(artists, (list, tuple))
            else text(artists)
        )
        track_id = text(meta.get("mpris:trackid"))
        if track_id == "/org/mpris/MediaPlayer2/TrackList/NoTrack":
            track_id = ""
        key = (track_id, url) if track_id or url else (title, artist)
        status = props.get("PlaybackStatus", "Stopped")
        position = seconds(props.get("Position"))
        rate = number(props.get("Rate"))
        rate = 1.0 if rate is None else rate
        length = seconds(meta.get("mpris:length"))
        state = self.active.get(name)
        if state and (state["key"] != key or now - state["time"] > POLL_SECONDS * 3):
            self.finish(name)
            state = None
        if state is None:
            if status != "Playing" or not any(key):
                return
            record = {
                "id": uuid4().hex,
                "device": self.device,
                "player": name.removeprefix(PREFIX),
                "url": url,
                "title": title,
                "artist": artist,
                "album": text(meta.get("xesam:album")),
                "started_at": at,
                "ended_at": at,
                "played_secs": 0.0,
                "track_secs": length if length else None,
                "max_position_secs": position if position is not None else 0.0,
                "seek_count": 0,
            }
            state = {
                "key": key,
                "record": record,
                "position": position,
                "status": status,
                "rate": rate,
                "time": now,
                "saved": now,
                "inferred_seek": None,
            }
            self.active[name] = state
        else:
            record = state["record"]
            elapsed = max(0, now - state["time"])
            if seek_position is not None:
                inferred = state["inferred_seek"]
                if not (
                    inferred
                    and now - inferred[1] <= POLL_SECONDS + 1
                    and abs(inferred[0] - seek_position) <= 2
                ):
                    record["seek_count"] += 1
                state["inferred_seek"] = None
            elif position is not None and state["position"] is not None:
                delta = position - state["position"]
                # Allow small timestamp/position jitter, but discard discontinuities.
                expected = elapsed * max(state["rate"], rate)
                if delta < -0.5 or delta > expected + 2:
                    if status != "Stopped":
                        record["seek_count"] += 1
                        state["inferred_seek"] = (position, now)
                elif state["status"] == "Playing" and delta > 0:
                    record["played_secs"] += delta
            record.update(
                url=url,
                title=title,
                artist=artist,
                album=text(meta.get("xesam:album")),
                track_secs=length if length else None,
                ended_at=max(record["ended_at"], at),
            )
            if position is not None:
                record["max_position_secs"] = max(record["max_position_secs"], position)
            state.update(position=position, status=status, rate=rate, time=now)
        if status == "Stopped":
            self.finish(name)
        elif now - state["saved"] >= CHECKPOINT_SECONDS:
            self.emit(dict(state["record"]))
            state["saved"] = now

    def close(self):
        for name in list(self.active):
            self.finish(name)


class Journal:
    def __init__(self, path):
        path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.file = path.open("a+b")
        try:
            fcntl.flock(self.file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            self.file.close()
            raise
        # A terminated write must not corrupt the next JSONL record.
        self.file.seek(0)
        end = 0
        for line in self.file:
            if not line.endswith(b"\n"):
                break
            json.loads(line)
            end += len(line)
        self.file.seek(end)
        self.file.truncate()

    def append(self, record):
        self.file.write(
            (json.dumps(record, ensure_ascii=False, allow_nan=False) + "\n").encode(
                "utf-8"
            )
        )
        self.file.flush()
        os.fsync(self.file.fileno())

    def close(self):
        self.file.close()


def run(path, device):
    from gi.repository import Gio, GLib

    os.umask(0o077)
    journal = Journal(path)
    tracker = Tracker(device, journal.append)
    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    loop = GLib.MainLoop()
    owners = {}

    def call(name, obj, interface, method, signature, args):
        return bus.call_sync(
            name,
            obj,
            interface,
            method,
            GLib.Variant(signature, args),
            None,
            Gio.DBusCallFlags.NO_AUTO_START,
            1000,
            None,
        ).unpack()

    def sample(name, seek_position=None):
        try:
            props = call(name, OBJECT, PROPERTIES, "GetAll", "(s)", (PLAYER,))[0]
        except GLib.Error:
            logging.warning(
                "Could not read player %s; ending at last observation", name
            )
            tracker.finish(name)
            return
        tracker.observe(
            name, props, timestamp(), clock(), seek_position=seconds(seek_position)
        )

    def poll():
        names = call(
            "org.freedesktop.DBus",
            "/org/freedesktop/DBus",
            "org.freedesktop.DBus",
            "ListNames",
            "()",
            (),
        )[0]
        names = {
            n for n in names if n.startswith(PREFIX) and n != PREFIX + "playerctld"
        }
        for name in list(owners):
            if name not in names:
                tracker.finish(name)
                del owners[name]
        for name in sorted(names):
            try:
                owner = call(
                    "org.freedesktop.DBus",
                    "/org/freedesktop/DBus",
                    "org.freedesktop.DBus",
                    "GetNameOwner",
                    "(s)",
                    (name,),
                )[0]
                if name in owners and owners[name] != owner:
                    tracker.finish(name)
                owners[name] = owner
                sample(name)
            except GLib.Error:
                tracker.finish(name)
        return GLib.SOURCE_CONTINUE

    def changed(_bus, sender, _path, interface, signal_name, params):
        for name, owner in list(owners.items()):
            if owner != sender:
                continue
            if signal_name == "Seeked":
                sample(name, params.unpack()[0])
            elif params.unpack()[0] == PLAYER:
                sample(name)

    def owner_changed(_bus, _sender, _path, _interface, _signal, params):
        name, old, new = params.unpack()
        if name.startswith(PREFIX) and name != PREFIX + "playerctld":
            if old:
                tracker.finish(name)
                owners.pop(name, None)
            if new:
                owners[name] = new
                sample(name)

    # Make callback failures fatal so systemd can restart instead of silently losing data.
    def guarded(callback):
        def invoke(*args):
            try:
                return callback(*args)
            except Exception:
                logging.exception("Collector failed")
                os._exit(1)

        return invoke

    bus.signal_subscribe(
        None,
        PROPERTIES,
        "PropertiesChanged",
        OBJECT,
        None,
        Gio.DBusSignalFlags.NONE,
        guarded(changed),
    )
    bus.signal_subscribe(
        None, PLAYER, "Seeked", OBJECT, None, Gio.DBusSignalFlags.NONE, guarded(changed)
    )
    bus.signal_subscribe(
        "org.freedesktop.DBus",
        "org.freedesktop.DBus",
        "NameOwnerChanged",
        "/org/freedesktop/DBus",
        None,
        Gio.DBusSignalFlags.NONE,
        guarded(owner_changed),
    )

    def stop():
        # Flush the last successfully observed position, not unobserved shutdown time.
        loop.quit()
        return GLib.SOURCE_REMOVE

    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, stop)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, stop)
    poll()
    GLib.timeout_add_seconds(POLL_SECONDS, guarded(poll))
    logging.info("Recording MPRIS locally to %s", path)
    try:
        loop.run()
    finally:
        tracker.close()
        journal.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
        / "mpris-media/plays.jsonl",
    )
    parser.add_argument("--device", default=socket.gethostname())
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    run(args.output, args.device)


if __name__ == "__main__":
    main()
