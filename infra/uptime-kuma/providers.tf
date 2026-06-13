terraform {
  backend "s3" {
    bucket                      = "homelab-infra-state"
    key                         = "uptime-kuma/terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    use_lockfile                = true
  }

  required_providers {
    uptimekuma = {
      source  = "breml/uptimekuma"
      version = "~> 0.1"
    }
  }
}

provider "uptimekuma" {
  endpoint = var.uptimekuma_endpoint
  username = var.uptimekuma_username
  password = var.uptimekuma_password
}

variable "uptimekuma_endpoint" {
  type        = string
  description = "Uptime Kuma endpoint URL"
}

variable "uptimekuma_username" {
  type        = string
  description = "Uptime Kuma username"
  sensitive   = true
}

variable "uptimekuma_password" {
  type        = string
  description = "Uptime Kuma password"
  sensitive   = true
}

variable "discord_webhook_url" {
  type        = string
  description = "Discord webhook URL for notifications"
  sensitive   = true
}
