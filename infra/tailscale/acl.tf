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
    "tag:server": ["autogroup:admin"]
  },

  "grants": [
    // Reachability for the identities that had it under the previous
    // wildcard grant is unchanged: the owner's own devices and the
    // tagged server / CI fleets keep full access.
    {"src": ["autogroup:member"], "dst": ["*"], "ip": ["*"]},
    {"src": ["tag:server"],       "dst": ["*"], "ip": ["*"]},
    {"src": ["tag:ci"],           "dst": ["*"], "ip": ["*"]},

    // Muse (muse-vm) is scoped to the endpoints it actually uses.
    // B450M-Pro4: Traefik HTTPS (tw.home and rdt.home MCP servers) and
    // the grafana-mcp tailnet forwarder (100.111.109.43:18995).
    {"src": ["muse-vm"], "dst": ["100.111.109.43"], "ip": ["tcp:443", "tcp:18995"]},
    // UM790-Pro: Traefik HTTPS (Ori MCP, home.yutakobayashi.com) and the
    // tinyproxy home-IP route, whose own config already allowlists this
    // VM only.
    {"src": ["muse-vm"], "dst": ["100.91.91.87"],   "ip": ["tcp:443", "tcp:8888"]}
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
