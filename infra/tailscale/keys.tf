resource "tailscale_tailnet_key" "nixos" {
  reusable      = true
  ephemeral     = false
  preauthorized = false
  description   = "nixos"
}

resource "tailscale_tailnet_key" "ci" {
  for_each = toset(["dotnix", "kasumilog"])

  reusable      = true
  ephemeral     = true
  preauthorized = true
  expiry        = 7776000 # 90 days
  tags          = ["tag:ci"]
  description   = "${each.key} CI Tailnet Lock"

  # Replacement must be coordinated with signing and GitHub Secret rotation.
  recreate_if_invalid = "never"

  depends_on = [tailscale_acl.main]
}
