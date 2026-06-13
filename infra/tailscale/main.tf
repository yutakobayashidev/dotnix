resource "tailscale_oauth_client" "ci" {
  depends_on = [tailscale_acl.main]
  description = "GitHub Actions CI"
  tags        = ["tag:ci"]
  scopes      = ["devices:core"]
}

output "ci_client_id" {
  value     = tailscale_oauth_client.ci.id
  sensitive = false
}

output "ci_client_secret" {
  value     = tailscale_oauth_client.ci.key
  sensitive = true
}
