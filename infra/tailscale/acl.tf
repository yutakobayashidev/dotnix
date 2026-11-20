resource "tailscale_acl" "main" {
  acl = <<EOF
{
  // The Muse personal-agent VM is enrolled by the Muse runtime, not by
  // this repository, so it has no Terraform-managed device entry or tag.
  // Its tailnet IP is the stable handle available today.
  "hosts": {
    "muse-vm": "100.83.176.125"
  },

  "tagOwners": {
    "tag:ci":     ["autogroup:admin"],
    "tag:initrd": ["autogroup:admin"],
    "tag:server": ["autogroup:admin"]
  },

  "grants": [
    // Reachability for the identities that had it under the previous
    // wildcard grant is unchanged: the owner's own devices and the
    // tagged server / CI fleets keep full access.
    {"src": ["autogroup:member"], "dst": ["*"], "ip": ["*"]},
    {"src": ["tag:server"],       "dst": ["*"], "ip": ["*"]},
    {"src": ["tag:ci"],           "dst": ["*"], "ip": ["*"]},

    // The global resolver must also be reachable by the restricted Muse VM.
    {"src": ["muse-vm"], "dst": ["100.111.109.43"], "ip": ["udp:53", "tcp:53"]},

    // Muse (muse-vm) is scoped to the endpoints it actually uses.
    // B450M-Pro4: Traefik HTTPS (tw.home and rdt.home MCP servers) and
    // the grafana-mcp tailnet forwarder (100.111.109.43:18995).
    {"src": ["muse-vm"], "dst": ["100.111.109.43"], "ip": ["tcp:443", "tcp:18995"]},
    // UM790-Pro: Traefik HTTPS (Ori MCP, home.yutakobayashi.com) and the
    // tinyproxy home-IP route, whose own config already allowlists this
    // VM only.
    {"src": ["muse-vm"], "dst": ["100.91.91.87"],   "ip": ["tcp:443", "tcp:8888"]}
  ],

  // Dedicated boot nodes may reply to inbound sessions, but cannot initiate
  // tailnet connections. Keep tag:initrd separate from tag:server/tag:ci.
  "tests": [
    {
      "src": "tag:initrd",
      "deny": [
        "100.111.109.43:22", "100.91.91.87:22", "tag:ci:443",
        "192.168.0.1:22", "192.168.0.13:22"
      ]
    },
    {"src": "tag:initrd", "proto": "udp", "deny": ["100.111.109.43:53", "192.168.0.1:53"]},
    {"src": "autogroup:member", "accept": ["tag:initrd:22", "tag:server:22"]},
    {"src": "tag:ci", "accept": ["100.111.109.43:443", "100.91.91.87:443"]}
  ],

  "ssh": [
    {
      "action": "check",
      "src":    ["autogroup:member"],
      "dst":    ["tag:server"],
      "users":  ["yuta","root"]
    }
  ],

  "nodeAttrs": [
    {
      "target": ["autogroup:member"],
      "attr":   ["funnel"]
    }
  ]
}
EOF
}
