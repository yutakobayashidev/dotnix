output "ci_auth_keys" {
  description = "Unsigned CI enrollment keys; sign on a trusted Tailnet Lock node before use."
  sensitive   = true
  value       = { for name, key in tailscale_tailnet_key.ci : name => key.key }
}

output "ci_auth_key_expiry" {
  description = "CI enrollment key expiry timestamps; rotate and re-sign before these dates."
  value       = { for name, key in tailscale_tailnet_key.ci : name => key.expires_at }
}
