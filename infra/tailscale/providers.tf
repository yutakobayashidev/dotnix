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

  encryption {
    key_provider "pbkdf2" "state_key" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "state_method" {
      keys = key_provider.pbkdf2.state_key
    }

    state {
      method    = method.aes_gcm.state_method
      enforced  = true
    }

    plan {
      method    = method.aes_gcm.state_method
      enforced  = true
    }
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

variable "state_encryption_passphrase" {
  type        = string
  sensitive   = true
  description = "Passphrase for OpenTofu state encryption (min 16 chars)"
}
