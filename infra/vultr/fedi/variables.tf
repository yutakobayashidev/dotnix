variable "region" {
  type        = string
  default     = "nrt"
  description = "Vultr region; nrt is Tokyo."
}

variable "plan" {
  type        = string
  default     = "vc2-2c-4gb"
  description = "Vultr plan. 1 GB of RAM was not enough to build Mastodon's assets on the current VPS."
}

variable "os_id" {
  type        = number
  description = "Vultr OS ID of the image that only boots the nixos-anywhere kexec installer, such as Ubuntu 24.04 x64. List IDs with `vultr-cli os list`."
}

variable "ssh_public_key" {
  type        = string
  description = "Public key that nixos-anywhere uses to log in to the fresh instance."
}

variable "state_encryption_passphrase" {
  type        = string
  sensitive   = true
  description = "Passphrase for OpenTofu state encryption (min 16 chars)"
}
