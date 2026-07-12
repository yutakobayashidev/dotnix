locals {
  default_notification_ids = [uptimekuma_notification.discord.id]
}

resource "uptimekuma_tag" "infra" {
  name  = "infrastructure"
  color = "#0066cc"
}

resource "uptimekuma_tag" "service" {
  name  = "service"
  color = "#00cc66"
}

resource "uptimekuma_monitor_group" "internal" {
  name   = "Internal"
  active = true
}

resource "uptimekuma_monitor_http" "gitea" {
  name             = "Gitea"
  url              = "https://git.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "webhashtag" {
  name             = "WebHashtag"
  url              = "https://tag.yutakobayashi.com/.well-known/webhashtag.json"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "nextcloud" {
  name             = "Nextcloud"
  url              = "https://cloud.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "immich" {
  name             = "Immich"
  url              = "https://photos.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "home_assistant" {
  name             = "Home Assistant"
  url              = "https://ha.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "navidrome" {
  name             = "Navidrome"
  url              = "https://music.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "n8n" {
  name             = "n8n"
  url              = "https://n8n.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "grafana" {
  name             = "Grafana"
  url              = "https://grafana.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "konomitv" {
  name             = "KonomiTV"
  url              = "https://tv.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "prometheus" {
  name             = "Prometheus"
  url              = "https://prometheus.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "birdclaw" {
  name             = "Birdclaw"
  url              = "https://birdclaw.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "tw" {
  name                  = "Twitter API Safe Proxy"
  url                   = "https://tw.home.yutakobayashi.com"
  accepted_status_codes = ["200-299", "404"]
  interval              = 60
  timeout               = 30
  max_retries           = 0
  retry_interval        = 60
  resend_interval       = 300
  active                = true
  method                = "GET"
  max_redirects         = 10
  parent                = uptimekuma_monitor_group.internal.id
  notification_ids      = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "mirakurun" {
  name             = "Mirakurun"
  url              = "https://mirakurun.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "edcb" {
  name             = "EDCB"
  url              = "https://edcb.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "rsshub" {
  name             = "RSSHub"
  url              = "https://rsshub.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "headroom" {
  name                  = "Headroom"
  url                   = "https://headroom.home.yutakobayashi.com"
  accepted_status_codes = ["200-299", "401", "404"]
  interval              = 60
  timeout               = 30
  max_retries           = 0
  retry_interval        = 60
  resend_interval       = 300
  active                = true
  method                = "GET"
  max_redirects         = 10
  parent                = uptimekuma_monitor_group.internal.id
  notification_ids      = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "aivisspeech" {
  name             = "AivisSpeech"
  url              = "https://aivisspeech.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "voicevox" {
  name             = "VOICEVOX"
  url              = "https://voicevox.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "archivebox" {
  name             = "ArchiveBox"
  url              = "https://archive.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "couchdb" {
  name                  = "CouchDB"
  url                   = "https://sync.home.yutakobayashi.com"
  accepted_status_codes = ["200-299", "401"]
  interval              = 60
  timeout               = 30
  max_retries           = 0
  retry_interval        = 60
  resend_interval       = 300
  active                = true
  method                = "GET"
  max_redirects         = 10
  parent                = uptimekuma_monitor_group.internal.id
  notification_ids      = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "nostr" {
  name             = "Nostr Relay"
  url              = "https://nostr.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "litellm" {
  name                  = "LiteLLM"
  url                   = "https://litellm.home.yutakobayashi.com"
  accepted_status_codes = ["200-299", "401", "404"]
  interval              = 60
  timeout               = 30
  max_retries           = 0
  retry_interval        = 60
  resend_interval       = 300
  active                = true
  method                = "GET"
  max_redirects         = 10
  parent                = uptimekuma_monitor_group.internal.id
  notification_ids      = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "niks3" {
  name             = "Niks3"
  url              = "https://niks3.yutakobayashi.com/health"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "nix_cache" {
  name             = "Nix Cache"
  url              = "https://nix-cache.yutakobayashi.com/nix-cache-info"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "uptime_kuma" {
  name             = "Uptime Kuma"
  url              = "https://status.home.yutakobayashi.com"
  interval         = 60
  timeout          = 30
  max_retries      = 0
  retry_interval   = 60
  resend_interval  = 300
  active           = true
  method           = "GET"
  max_redirects    = 10
  parent           = uptimekuma_monitor_group.internal.id
  notification_ids = local.default_notification_ids
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}
