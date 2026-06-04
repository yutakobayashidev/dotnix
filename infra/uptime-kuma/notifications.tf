resource "uptimekuma_notification" "discord" {
  name      = "Discord"
  type      = "discord"
  is_active = true
  config = jsonencode({
    discordWebhookUrl  = var.discord_webhook_url
    discordUsername    = "Uptime Kuma"
    discordMessageFormat = "normal"
  })
}
