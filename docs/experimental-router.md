# Experimental IPv4 router

Status: implemented for evaluation and isolated VM testing; **disabled on UM790-Pro**.
Do not push an enabled host configuration or run `switch`, `boot`, or `test`
on a physical host without explicit approval. Comin deploys main automatically.

## Observed baseline (2026-11-13)

Read-only SSH inspection confirmed NetworkManager owns `wlp2s0`, with a
DHCP IPv4 address in `192.168.0.0/24` and default gateway `192.168.0.1`.
`enp1s0` has no address or carrier. systemd-networkd is inactive. The host
also has a working IPv6 default route on Wi-Fi; this feature does not change it.
Docker uses `172.17.0.0/16` through `172.20.0.0/16`, VirtualBox uses
`192.168.56.0/24`, and Tailscale installs its own table 52 and policy rules.
No route in the inspected tables overlapped `10.77.10.0/24`.

The active NixOS firewall uses iptables. Root-only `nft list ruleset` could
not be read with the available account (`sudo -n` requires a password).
Consequently live Docker/Tailscale rule ordering remains a pre-deployment
check. No permission, network or service settings were changed for inspection.
B450M CoreDNS answered an A query from UM790 over its Tailscale address.
This proves host-to-resolver reachability, not physical experiment-client access.

## Architecture and options

`modules/features/network/experimental-router/default.nix` registers a flake-parts
NixOS module. Its implementation stays in `module.nix`; the directory boundary
prevents the helper from being independently discovered as a flake module.
UM790 imports `experimental-router.nix`, with `enable = false`.

All options are under `my.services.experimentalRouter`:

| Option         | Default          | Meaning                                            |
| -------------- | ---------------- | -------------------------------------------------- |
| `enable`       | `false`          | Opt in only after approval                         |
| `wanInterface` | `wlp2s0`         | Existing WAN route; no Wi-Fi configuration changes |
| `lanInterface` | `enp1s0`         | Dedicated physical experiment port                 |
| `subnetId`     | `10`             | LAN is `10.77.<subnetId>.0/24`, gateway `.1`       |
| `upstreamDNS`  | `100.111.109.43` | Existing B450M CoreDNS via Tailnet                 |

A bounded /24 avoids premature multi-LAN abstractions. Interface names are
validated and WAN/LAN equality is rejected. `preflight.py` reads all IPv4
routing tables at service startup and rejects overlap on other interfaces.
It cannot predict a future VPN route or subnet change: repeat the audit before
each experiment and after VPN/container changes. There is no route override,
Tailscale route advertisement, exit node, VLAN, IPv6 PD, or WARP configuration.

Only the LAN is excluded from NetworkManager and dhcpcd. networkd matches that
interface exactly, assigns `.1/24`, and serves DHCP `.100`–`.199` with a one-hour
lease. No DHCP client, IPv6 link-local address, RA reception or RA emission is
enabled on that link. It is not required for network-online. Never connect this
port to the household switch/AP: software cannot distinguish an experiment PC
from an accidentally connected household broadcast domain.

networkd supplies DHCP; dnsmasq is DNS-only, bound to the LAN address/interface,
with no DHCP range, host resolver changes or cache. It forwards to existing
CoreDNS. Clients receive the gateway as DNS, not the Tailnet address, so they
need no Tailnet membership or route. A CoreDNS answer pointing at a private or
Tailnet address does not grant access to it. DNS failure is independent of NAT:
verify internet reachability with a known numeric IPv4 endpoint first.

## Firewall coexistence

The upstream `networking.nftables.enable` changes NixOS's whole firewall backend.
This feature deliberately leaves it off, keeps `networking.firewall.enable` on,
and owns only `inet dotnix_experimental_router` through a systemd unit and the
existing firewall's extraCommands hook. It never flushes the global ruleset.
The hook installs the nftables guard before inserting two interface/source-bound
IPv4 FORWARD accepts, necessary when Docker's FORWARD policy is DROP.

The nftables input/forward hooks run at priority -10, before iptables filtering.
A drop is final even if Docker or Tailscale would later accept the packet.
An accept still traverses other base chains. Only traffic touching the experiment
interface is restricted; all other packets continue through existing policy.
The table is replaced in one nft transaction, including on reload.

- LAN → host: DHCP, gateway DNS (UDP/TCP), and gateway IPv4 ping only.
- LAN → WAN: correctly sourced IPv4 only; deny RFC1918, CGNAT/Tailnet,
  loopback, link-local, multicast/reserved destinations before accepting.
- WAN → LAN: established/related IPv4 only. Other new ingress is dropped.
- LAN ↔ other interfaces: denied, including Docker bridges and Tailscale.
- IPv6 touching the LAN: denied regardless of global forwarding or client
  static addressing. Tailscale's existing global IPv6 settings are preserved.

Masquerade is restricted to LAN ingress, WAN egress and the LAN source prefix.
No household DHCP, HGW, AP, Wi-Fi profile, global IPv6 default route or DNS
settings are changed. Named nft counters record input/forward drops without
logging every packet. Service shutdown lowers the LAN link before deleting its
table; networkd and dnsmasq depend on that service. Firewall restart and Docker
restart behavior must also be checked in the approved physical trial.

## Verification without physical activation

Use the configured builder or a separate VM-capable Linux machine, not a
space-constrained local Nix store. The test runs disposable QEMU VMs and only
changes networking _inside those VMs_:

```sh
nix build .#checks.x86_64-linux.experimental-router -L --no-link
nix eval .#nixosConfigurations.UM790-Pro.config.system.build.toplevel.drvPath
```

The flake check creates upstream/router/client nodes with Docker on the router.
It tests DHCP/default gateway, numeric HTTP connectivity, observed NAT source,
DNS forwarding, private upstream rejection, unsolicited WAN rejection, forced
IPv6 rejection, nft syntax/reload, overlap preflight and link shutdown.
This is not a physical Wi-Fi throughput, Tailnet ACL or packet capture audit.
The existing CI gates Nix work behind `NIX_BUILD_ENABLED`; no workflow is enabled
or modified by this feature. Run the new check explicitly: the current CI does
not automatically build every VM check.

## Validation record (2026-11-13)

- UM790 full NixOS `system.build.toplevel.drvPath` evaluation passed with the
  feature both disabled and enabled; no physical system closure was activated.
- Disabled evaluation contains no experiment service. Enabled evaluation has
  exactly one DHCP-server network, `20-experimental-lan`. Wi-Fi profiles,
  nameservers and Tailscale enable/routing/up/set flags compare equal to baseline.
- Equal WAN/LAN names and an invalid interface name are rejected during evaluation.
  The VM test rejects an injected overlapping route at startup preflight.
- The QEMU check passed, including IPv6 forward-drop counter growth with static
  addresses/neighbours, Docker restart, firewall reload and controlled shutdown.
  Socket-triggered networkd reactivation found during testing was fixed by
  stopping its socket together with the experiment service.
- Nix formatting, Python formatting/lint, dashboard JSON and whitespace checks
  passed. The whole repository CI and a physical deployment were not run.

After testing, the real UM790 still had enp1s0 down without an address, its
original Wi-Fi default gateway, NetworkManager and Tailscale active, networkd
inactive, and no installed experiment service. Physical-client DHCP, Wi-Fi
throughput, root-only live rule inspection, and full previous-generation
activation remain approval-gated validation work.

## Monitoring

The provisioned `Experimental Router` dashboard uses the existing UM790 node
exporter and VictoriaMetrics scrape job. It shows RX/TX bytes, packet drops,
interface state, CPU and memory. WAN traffic includes existing host/container
traffic, so it must not be interpreted as experiment-only throughput. A down LAN
before cabling is expected. There is no new exporter or sFlow collector.

Inspect rejection counters after an approved deployment with:

```sh
sudo nft list table inet dotnix_experimental_router
```

Counters reset when the table is replaced. They are not exported to Grafana in
this version. The dashboard is provisioned on the next separately approved
B450M deployment; it does not enable the router.

## Approval and physical trial

Before approval: review the exact diff and evaluated enabled configuration,
repeat address/route/container inventory, inspect root-only nft/iptables rules,
and confirm a physical console and known-good boot entry. Confirm enp1s0 is
connected **only** to the experiment PC (or an isolated switch with no uplink).
Record DNS results and existing Docker/Tailscale service connectivity for comparison.

After explicit approval only:

1. Suspend the Comin deployment loop (`sudo systemctl stop comin`) during the
   controlled trial. Do not publish `enable = true` to main. Keep a second
   management session plus the physical console available.
2. Build the reviewed enabled configuration without activating it. Keep the
   known-good `/run/current-system` path and protect it from garbage collection.
3. Arm an independent five-minute recovery timer **before** activating. For example,
   with `router_previous` set to the reviewed known-good store path:

   ```sh
   router_previous=$(readlink -f /run/current-system)
   sudo systemd-run --unit=experimental-router-rollback --on-active=5m \
     "$router_previous/bin/switch-to-configuration" test
   ```

4. Use the reviewed built configuration's `bin/switch-to-configuration test`.
   Check Wi-Fi gateway and IPv6 route, Tailscale SSH, existing containers, LAN
   DHCP, numeric WAN connectivity, DNS, private-network rejection and IPv6
   rejection. Verify the networkd file and DHCP listener are LAN-only. Check
   firewall rule ordering again after Docker/firewall restarts in this trial.
5. Cancel the timer only after all checks succeed. A permanent switch/Comin
   enablement requires a separate reviewed decision. Restore the disabled
   configuration and restart Comin before ending an unsuccessful trial.

The timer is not a substitute for a console: systemd, storage or an unrelated
activation failure can prevent automatic recovery. `test` does not update the
persistent boot default. A successful test alone is not a permanent deployment.

## Rollback

Disconnect the experiment cable first. From the console or surviving management
session, activate the recorded known-good path using its
`bin/switch-to-configuration test`; do not guess which generation `--rollback`
selects. Verify DHCP/DNS services and the experiment table are gone, enp1s0 has
no experiment address, and the Wi-Fi default route, DNS, Tailnet and containers
match the recorded baseline. If needed, keep enp1s0 down until its stale address
is removed and ownership is confirmed. Restore `enable = false` in the source.
Only restart Comin when its tracked configuration is also disabled, or it could
immediately reapply the experimental version. If remote access fails, use the
physical console/known-good boot entry; reconnect the experiment PC to its prior
network. The household gateway and AP never need reconfiguration.

## Later stages and references

First validate the single wired client. Next, consider a managed 802.1Q switch
with an isolated access port and a dedicated router with separate wired WAN/LAN
ports; keep a separate console/management path. Benchmark before choosing 10GbE.
Then design explicit management/Trusted/Servers/IoT/Guest policy and test each
boundary before adding VLANs. IPv6 PD/RA, flow telemetry, DNS64/NAT64 and WARP
are independent future projects, not prerequisites for this IPv4 trial.

References reviewed: [chlorinate router modules](https://github.com/rokoucha/chlorinate/tree/master/nixos/modules/router),
[NixOS migration experience](https://chun37.hatenablog.com/entry/2026/06/18/201800),
[systemd network configuration](https://www.freedesktop.org/software/systemd/man/latest/systemd.network.html),
[nftables chain priorities](https://wiki.nftables.org/wiki-nftables/index.php/Configuring_chains).
The reference's wholesale firewall replacement and multi-WAN/IPv6 features are
not copied. Future-only references: [CoreDNS](https://github.com/nyanshiba/corednsconf),
[Grafana](https://github.com/nyanshiba/grafanaconf),
[WARP](https://github.com/nyanshiba/warp-router),
[NAT64](https://github.com/nyanshiba/nat64-on-link).
