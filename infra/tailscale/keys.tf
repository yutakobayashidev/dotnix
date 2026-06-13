resource "tailscale_tailnet_key" "nixos" {
  reusable      = true
  ephemeral     = false
  preauthorized = false
  description   = "nixos"
}
