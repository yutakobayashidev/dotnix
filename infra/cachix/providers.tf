terraform {
  encryption {
    method "unencrypted" "migrate" {}

    key_provider "pbkdf2" "state_key" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "state_method" {
      keys = key_provider.pbkdf2.state_key
    }

    state {
      method = method.aes_gcm.state_method
      fallback {
        method = method.unencrypted.migrate
      }
      # TODO: add "enforced = true" after first successful apply
    }

    plan {
      method = method.aes_gcm.state_method
      fallback {
        method = method.unencrypted.migrate
      }
      # TODO: add "enforced = true" after first successful apply
    }
  }

  required_providers {
    cachix = {
      source  = "takeokunn/cachix"
      version = "~> 1.0"
    }
  }
}

provider "cachix" {
  # auth_token = var.cachix_token  # Or set CACHIX_AUTH_TOKEN env var
}

variable "state_encryption_passphrase" {
  type        = string
  sensitive   = true
  description = "Passphrase for OpenTofu state encryption (min 16 chars)"
}
