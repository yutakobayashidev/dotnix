resource "tailscale_oauth_client" "ci" {
  depends_on  = [tailscale_acl.main]
  description = "GitHub Actions CI"
  tags        = ["tag:ci"]
  # add auth_keys so the OAuth client can create auth keys for CI nodes
  scopes = ["devices:core", "auth_keys"]
}

resource "tailscale_oauth_client" "kasumilog_archive" {
  depends_on  = [tailscale_acl.main]
  description = "GitHub Actions kasumilog archive collection"
  tags        = ["tag:ci"]
  scopes      = ["devices:core", "auth_keys"]
}

output "ci_client_id" {
  value     = tailscale_oauth_client.ci.id
  sensitive = false
}

output "ci_client_secret" {
  value     = tailscale_oauth_client.ci.key
  sensitive = true
}

output "kasumilog_archive_client_id" {
  value     = tailscale_oauth_client.kasumilog_archive.id
  sensitive = false
}

output "kasumilog_archive_client_secret" {
  value     = tailscale_oauth_client.kasumilog_archive.key
  sensitive = true
}
