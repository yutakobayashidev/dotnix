# CoreDNS

| File                                 | Responsibility                                     |
| ------------------------------------ | -------------------------------------------------- |
| `default.nix`, `policy.nix`          | NixOS wiring and reproducible policy build         |
| `Corefile`, `zones.conf`             | Public filtering and isolated home/MagicDNS routes |
| `forward.conf`, `cache.conf`         | Quad9 → Cloudflare failover and cache behavior     |
| `sources.json`, `generate-policy.py` | Pinned upstream lists and offline compilation      |
| `allowlist.txt`, `blocklist.txt`     | Local exceptions and additions                     |

## Filtering

The configuration draws on [nyanshiba's CoreDNS configuration](https://github.com/nyanshiba/corednsconf)
and [Unbound article](https://nyanshiba.com/blog/unbound/). It uses standard CoreDNS
plugins, HaGeZi **Normal**, and AdGuard's original CNAME tracker targets. It does
not import the author's broad TLD/cloud-provider restrictions or DNS64 routing.

Listed domains and their subdomains return **NOERROR with no address or service
records** (NODATA), including A, AAAA, HTTPS and SVCB. A sparse `file` zone stores
TXT markers (`"blocked"`) for these names and their wildcards. Only absent names
fall through to the upstream resolver. Parent/child entries are compressed to
preserve DNS wildcard behavior; unlisted parent names still resolve upstream.
TXT queries for blocked names return the diagnostic marker. Root SOA queries
return the local policy zone's SOA. This is a filtering recursive service, not
an authoritative copy of the public root zone.

Known CNAME tracker targets are rewritten to `blocked.invalid`, resolved locally
as NXDOMAIN. Responses no longer contain the tracker's address/service records.
This targets the dedicated CNAME list, not every possible alias into HaGeZi.
HTTPS/SVCB AliasMode targets are not CNAME records and are not inspected by this
rewrite rule. Direct queries for listed names are still blocked for these types.

Add a queried domain to `allowlist.txt` to bypass local direct and CNAME filtering
for that domain and its descendants. For a broken site, prefer its exact queried
hostname. Quad9's independent filtering still applies. Exceptions overlapping
internal zones are rejected during the build. `blocklist.txt` adds local blocked
subtrees; the allowlist takes precedence.

## Cache and availability

The cache matches nyanshiba/corednsconf: `cache { serve_stale 24h immediate }`.
Normal responses follow upstream TTLs within CoreDNS default limits. Expired
answers can be returned immediately for up to 24 hours after expiry while a
background refresh runs, including when upstreams are healthy. No prefetch or
custom negative/SERVFAIL cache settings are applied.
Internal home/MagicDNS zones do not use this stale cache. CoreDNS/B450M failure
still interrupts DNS: Cloudflare is an upstream fallback, not a replacement for
the CoreDNS server. DNS filtering cannot remove ads served from the same hostname
as wanted content, and applications with independent DoH can bypass it.

## Updating lists

`sources.json` pins raw GitHub URLs to commits and SHA-256 hashes. There is no
runtime download, startup dependency on GitHub, or scheduled list update.

1. Pick new commits from [HaGeZi](https://github.com/hagezi/dns-blocklists/commits/main/)
   and [AdGuard](https://github.com/AdguardTeam/cname-trackers/commits/master/).
2. Replace the commit in each source URL. Run `nix store prefetch-file --json '<new URL>'`
   and copy its `hash` into the corresponding entry in `sources.json`.
3. Run `nix build .#checks.x86_64-linux.coredns`, review the diff, and deploy normally.

The check starts the packaged CoreDNS against the full pinned policy plus isolated
fixtures. Loopback upstreams verify block types, wildcard depth, exceptions, CNAME
chains and label boundaries, internal routes, Quad9 priority, failover, NXDOMAIN
preservation, recovery, and stale answers. Invalid rules fail the build.

To run this check independently when another host prevents flake-wide checks from
evaluating, use the following command from the repository root:

```sh
nix build --impure --expr '
  let f = builtins.getFlake (toString ./.);
  in import ./tests/coredns.nix { pkgs = f.nixosConfigurations.B450M-Pro4.pkgs; }
'
```
