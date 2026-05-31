terraform {
  required_providers {
    gitea = {
      source  = "go-gitea/gitea"
      version = "0.3.0"
    }
  }
}

provider "gitea" {
  base_url = "https://git.home.yutakobayashi.com"
}
