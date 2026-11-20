variable "discord_infra_info_webhook_url" {
  type        = string
  sensitive   = true
  description = "Existing Alertmanager discord-infra-info webhook URL from secrets/alertmanager.yaml"

  validation {
    condition     = can(regex("^https://discord\\.com/api/webhooks/[0-9]+/[^/?[:space:]]+$", var.discord_infra_info_webhook_url))
    error_message = "Provide the existing infra-info Discord webhook URL."
  }
}

resource "tailscale_webhook" "infra_info" {
  endpoint_url  = var.discord_infra_info_webhook_url
  provider_type = "discord"
  subscriptions = [
    "categoryDeviceMisconfigurations",
    "categoryTailnetManagement",
  ]
}
