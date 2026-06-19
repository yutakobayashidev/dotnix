variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "fingerprint" {
  type = string
}

variable "region" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "image_id" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "state_encryption_passphrase" {
  type        = string
  sensitive   = true
  description = "Passphrase for OpenTofu state encryption (min 16 chars)"
}
