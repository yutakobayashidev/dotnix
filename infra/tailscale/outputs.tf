output "ci_auth_keys" {
  description = "Unsigned CI enrollment keys; sign on a trusted Tailnet Lock node before use."
  sensitive   = true
  value       = { for name, key in tailscale_tailnet_key.ci : name => key.key }
}

output "ci_auth_key_expiry" {
  description = "CI enrollment key expiry timestamps; rotate and re-sign before these dates."
  value       = { for name, key in tailscale_tailnet_key.ci : name => key.expires_at }
}

output "initrd_auth_keys" {
  description = "Unsigned B450M-Pro4 initrd enrollment keys, indexed by generation."
  sensitive   = true
  value       = { for generation, key in tailscale_tailnet_key.initrd : generation => key.key }
}

output "initrd_auth_key_expiry" {
  description = "Initrd enrollment deadlines; deployment and reboot verification must precede expiry."
  value       = { for generation, key in tailscale_tailnet_key.initrd : generation => key.expires_at }
}
