terraform {
  backend "s3" {
    bucket                      = "homelab-infra-state"
    key                         = "gitea/terraform.tfstate"
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
    gitea = {
      source  = "go-gitea/gitea"
      version = "~> 0.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "gitea_base_url" {
  type    = string
  default = "https://git.yutakobayashi.com"
}

provider "gitea" {
  base_url = var.gitea_base_url
}
