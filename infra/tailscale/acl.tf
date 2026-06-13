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
