# Tailnet DNS

Tailscale distributes `100.111.109.43` (CoreDNS on B450M-Pro4) as the sole global
nameserver, with local DNS override enabled. Clients accept this configuration;
Linux desktops use systemd-resolved without static nameservers or search domains.
The explicit `home.yutakobayashi.com` split route points to the same CoreDNS.

CoreDNS answers `home.yutakobayashi.com` and its subdomains with the B450M Tailnet
address. For public names it tries Quad9 (`9.9.9.9`) first, then Cloudflare
(`1.1.1.1`) on network errors, timeouts, SERVFAIL or REFUSED. `policy sequential`
makes the order meaningful. NXDOMAIN is returned unchanged, including Quad9
blocking responses. Healthy Quad9 is preferred again after recovery.

MagicDNS names are still answered by Tailscale. B450M disables Tailscale DNS
acceptance, uses its local CoreDNS, and forwards only its Tailnet domain to
`100.100.100.100`, avoiding a default-forwarding loop. Applications with their own
DoH configuration and exit-node DNS behavior are outside this OS DNS policy.

CoreDNS remains a single point of failure: if B450M or CoreDNS is unavailable,
uncached ordinary and home-domain lookups fail. Cloudflare is an **upstream**
fallback; it cannot replace an unavailable CoreDNS. Do not add public nameservers
alongside CoreDNS in Tailscale: those are not ordered standby resolvers.

## Rollout and verification

1. Push the Nix configuration and wait for Comin to activate CoreDNS on B450M.
2. Run the `Infra: Approved OpenTofu deploy` workflow for `tailscale` in plan mode,
   review the DNS and resolver-access changes, then run apply for the same revision.
3. Accept the corresponding Comin generation on desktops that require confirmation.
4. Check `tailscale dns status`, `resolvectl status`, and queries for a public name,
   `unifi.home.yutakobayashi.com`, and a MagicDNS host. CoreDNS metrics on B450M at
   `127.0.0.1:9153` expose upstream request counts.

The deployment test uses a separate CoreDNS process and loopback-only mock DNS
servers to verify primary preference, failover, NXDOMAIN preservation, and recovery
without disrupting production DNS.
