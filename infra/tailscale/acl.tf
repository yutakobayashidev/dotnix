resource "tailscale_acl" "main" {
  acl = <<EOF
{
  "tagOwners": {
    "tag:ci":     ["autogroup:admin"],
    "tag:server": ["autogroup:admin"]
  },
  "grants": [
    {"src": ["*"], "dst": ["*"], "ip": ["*"]}
  ],
  "ssh": [
    {
      "action": "check",
      "src":    ["autogroup:member"],
      "dst":    ["autogroup:self"],
      "users":  ["autogroup:nonroot", "root"]
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
