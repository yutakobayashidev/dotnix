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
  name           = "Gitea"
  url            = "https://git.home.yutakobayashi.com"
  interval       = 60
  timeout        = 30
  max_retries    = 2
  retry_interval = 60
  active         = true
  method         = "GET"
  max_redirects  = 10
  parent         = uptimekuma_monitor_group.internal.id
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "nextcloud" {
  name           = "Nextcloud"
  url            = "https://cloud.home.yutakobayashi.com"
  interval       = 60
  timeout        = 30
  max_retries    = 2
  retry_interval = 60
  active         = true
  method         = "GET"
  max_redirects  = 10
  parent         = uptimekuma_monitor_group.internal.id
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "immich" {
  name           = "Immich"
  url            = "https://photos.home.yutakobayashi.com"
  interval       = 60
  timeout        = 30
  max_retries    = 2
  retry_interval = 60
  active         = true
  method         = "GET"
  max_redirects  = 10
  parent         = uptimekuma_monitor_group.internal.id
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "home_assistant" {
  name           = "Home Assistant"
  url            = "https://ha.home.yutakobayashi.com"
  interval       = 60
  timeout        = 30
  max_retries    = 2
  retry_interval = 60
  active         = true
  method         = "GET"
  max_redirects  = 10
  parent         = uptimekuma_monitor_group.internal.id
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "navidrome" {
  name           = "Navidrome"
  url            = "https://music.home.yutakobayashi.com"
  interval       = 60
  timeout        = 30
  max_retries    = 2
  retry_interval = 60
  active         = true
  method         = "GET"
  max_redirects  = 10
  parent         = uptimekuma_monitor_group.internal.id
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "n8n" {
  name           = "n8n"
  url            = "https://n8n.home.yutakobayashi.com"
  interval       = 60
  timeout        = 30
  max_retries    = 2
  retry_interval = 60
  active         = true
  method         = "GET"
  max_redirects  = 10
  parent         = uptimekuma_monitor_group.internal.id
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "grafana" {
  name           = "Grafana"
  url            = "https://grafana.home.yutakobayashi.com"
  interval       = 60
  timeout        = 30
  max_retries    = 2
  retry_interval = 60
  active         = true
  method         = "GET"
  max_redirects  = 10
  parent         = uptimekuma_monitor_group.internal.id
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "konomitv" {
  name           = "KonomiTV"
  url            = "https://tv.home.yutakobayashi.com"
  interval       = 60
  timeout        = 30
  max_retries    = 2
  retry_interval = 60
  active         = true
  method         = "GET"
  max_redirects  = 10
  parent         = uptimekuma_monitor_group.internal.id
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "prometheus" {
  name           = "Prometheus"
  url            = "https://prometheus.home.yutakobayashi.com"
  interval       = 60
  timeout        = 30
  max_retries    = 2
  retry_interval = 60
  active         = true
  method         = "GET"
  max_redirects  = 10
  parent         = uptimekuma_monitor_group.internal.id
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
  max_retries           = 2
  retry_interval        = 60
  active                = true
  method                = "GET"
  max_redirects         = 10
  parent         = uptimekuma_monitor_group.internal.id
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}

resource "uptimekuma_monitor_http" "cloudflare_error_page" {
  name                  = "Cloudflare Error Page"
  url                   = "http://localhost:5000"
  accepted_status_codes = ["500-599"]
  interval              = 60
  timeout               = 30
  max_retries           = 2
  retry_interval        = 60
  active                = true
  method                = "GET"
  max_redirects         = 10
  parent         = uptimekuma_monitor_group.internal.id
  tags = [
    {
      tag_id = uptimekuma_tag.service.id
    },
  ]
}
