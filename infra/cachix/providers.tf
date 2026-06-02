terraform {
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
