terraform {
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
