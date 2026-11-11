variable "client_secrets" {
  description = "Client secrets shared with the applications through SOPS"
  type = object({
    ori         = string
    ori-chatgpt = string
    ori-muse    = string
    ori-hermes  = string
    grafana     = string
    linkding    = string
    immich      = string
    moe         = string
    gitea       = string
    nextcloud   = string
  })
  sensitive = true
}

variable "state_encryption_passphrase" {
  description = "Passphrase for OpenTofu state encryption (min 16 chars)"
  type        = string
  sensitive   = true
}
