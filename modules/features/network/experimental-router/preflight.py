"""Read-only overlap check immediately before starting the experimental LAN."""

import ipaddress
import json
import subprocess
import sys

lan, wan, subnet = sys.argv[1:]
network = ipaddress.ip_network(subnet)
links = json.loads(subprocess.check_output(["ip", "-j", "link", "show"]))
by_name = {link["ifname"]: link for link in links}
for name in (lan, wan):
    if name not in by_name or "master" in by_name[name]:
        sys.exit(f"Missing or enslaved experimental-router interface: {name}")
addresses = json.loads(
    subprocess.check_output(["ip", "-j", "-4", "addr", "show", "dev", lan])
)
for link in addresses:
    for address in link.get("addr_info", []):
        if ipaddress.ip_address(address["local"]) != network.network_address + 1:
            sys.exit("Experimental LAN already has a different IPv4 address")
routes = json.loads(
    subprocess.check_output(["ip", "-j", "-4", "route", "show", "table", "all"])
)
for route in routes:
    destination = route.get("dst", "default")
    if destination == "default" or route.get("dev") == lan:
        continue
    if network.overlaps(ipaddress.ip_network(destination, strict=False)):
        sys.exit(f"Experimental LAN overlaps route {destination} on {route.get('dev')}")
