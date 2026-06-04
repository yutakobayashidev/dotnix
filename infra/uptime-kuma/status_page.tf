resource "uptimekuma_status_page" "main" {
  slug        = "services"
  title       = "System Status"
  description = "Internal service status for home infrastructure"
  published   = true
  show_tags   = true
  theme       = "auto"

  public_group_list = [
    {
      name   = "Services"
      weight = 1
      monitor_list = [
        {
          id       = uptimekuma_monitor_http.gitea.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.nextcloud.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.immich.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.home_assistant.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.navidrome.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.n8n.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.grafana.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.konomitv.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.prometheus.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.tw.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.mirakurun.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.edcb.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.rsshub.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.headroom.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.aivisspeech.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.archivebox.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.couchdb.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.cloudflare_error_page.id
          send_url = false
        },
      ]
    },
  ]
}
