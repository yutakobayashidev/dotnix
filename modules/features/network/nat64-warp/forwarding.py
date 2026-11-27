"""Preserve host sysctls while enabling the IPv6 routing gate and selected links."""

import json
import sys
from pathlib import Path

mode, lan, tap, state_file = sys.argv[1:]
state = Path(state_file)
if mode == "enable":
    # IPv6 routing has a global gate. Changing it also changes per-link flags;
    # preserve every existing link/default flag, then enable only LAN and TAP.
    global6 = "/proc/sys/net/ipv6/conf/all/forwarding"
    paths = (
        [global6]
        + [
            str(p)
            for p in Path("/proc/sys/net/ipv6/conf").glob("*/forwarding")
            if str(p) != global6
        ]
        + [f"/proc/sys/net/ipv4/conf/{iface}/forwarding" for iface in (lan, tap)]
    )
    paths.append(f"/proc/sys/net/ipv6/conf/{lan}/accept_ra")
    if not state.exists():
        state.write_text(json.dumps({p: Path(p).read_text() for p in paths}))
    saved = json.loads(state.read_text())
    Path(global6).write_text("1")
    for path, value in saved.items():
        if path == global6:
            continue
        if path.endswith("/forwarding") and path.split("/")[-2] in (lan, tap):
            value = "1"
        elif path.endswith("/accept_ra"):
            value = "2"
        Path(path).write_text(value)

else:
    if state.exists():
        for path, value in json.loads(state.read_text()).items():
            if Path(path).exists():
                Path(path).write_text(value)
        state.unlink()
