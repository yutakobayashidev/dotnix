terraform {
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
