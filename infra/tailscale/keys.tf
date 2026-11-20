resource "tailscale_tailnet_key" "nixos" {
  reusable      = true
  ephemeral     = false
  preauthorized = false
  description   = "nixos"
}

resource "tailscale_tailnet_key" "ci" {
  for_each = toset(["dotnix", "kasumilog", "snapshots"])

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

# Keep both generations during rotation; remove the old entry only after a
# successful reboot with the replacement installed in the boot artifacts.
variable "initrd_key_generations" {
  description = "B450M-Pro4 enrollment generations retained during coordinated rotation."
  type        = set(string)
  default     = ["2026-11"]
}

resource "tailscale_tailnet_key" "initrd" {
  for_each = var.initrd_key_generations

  reusable      = true
  ephemeral     = true
  preauthorized = true
  expiry        = 7776000 # 90 days; update the installed initrd before expiry.
  tags          = ["tag:initrd"]
  description   = "B450M-Pro4 initrd ${each.key}"

  # Never silently rotate without delivering the new key to the boot artifact.
  recreate_if_invalid = "never"

  depends_on = [tailscale_acl.main]
}
