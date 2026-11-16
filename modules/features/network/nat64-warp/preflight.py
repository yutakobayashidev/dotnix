"""Read-only checks before assigning the lab link; never probe/send RA."""

import ipaddress
import json
import subprocess
import sys


def ip(*args):
    return json.loads(subprocess.check_output(["ip", "-j", *args], text=True))


tap, lan = sys.argv[1:]
links = {item["ifname"]: item for item in ip("link", "show")}
if lan not in links or tap not in links:
    raise SystemExit("NAT64 requires the explicitly selected LAN and existing TAP")
for family, reserved in (
    ("-4", ["192.168.254.0/30", "192.0.2.0/24"]),
    ("-6", ["fd64:35::/64", "64:ff9b:1:35::/96"]),
):
    networks = [ipaddress.ip_network(n) for n in reserved]
    for route in ip(family, "route", "show", "table", "all"):
        dst = route.get("dst", "default")
        if dst == "default" or route.get("dev") == tap:
            continue
        net = ipaddress.ip_network(dst, strict=False)
        if any(net.overlaps(n) for n in networks):
            raise SystemExit(f"NAT64 address overlap: {dst} on {route.get('dev')}")
    if any(
        str(r.get("table")) == "1064"
        for r in ip(family, "route", "show", "table", "all")
    ):
        raise SystemExit("NAT64 routing table 1064 is already occupied")
    for rule in ip(family, "rule", "show"):
        if rule.get("priority") == 1064:
            raise SystemExit("NAT64 policy-rule priority 1064 is already occupied")
