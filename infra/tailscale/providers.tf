terraform {
  backend "s3" {
    bucket                      = "homelab-infra-state"
    key                         = "tailscale/terraform.tfstate"
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
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.15"
    }
  }
}

provider "tailscale" {
  api_key = var.tailscale_api_key
}

variable "tailscale_api_key" {
  type        = string
  sensitive   = true
  description = "Tailscale API access token"
}
