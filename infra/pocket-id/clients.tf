locals {
  clients = {
    ori-muse = {
      name          = "Ori MCP (Muse)"
      launch_url    = "https://agent.meta.ai"
      callback_urls = ["https://agent.meta.ai/api/hatch/oauth/callback"]
      pkce_enabled  = true
    }
    ori = {
      name          = "Ori"
      launch_url    = "https://home.yutakobayashi.com"
      callback_urls = ["https://home.yutakobayashi.com/api/auth/callback"]
      pkce_enabled  = true
    }
    ori-chatgpt = {
      name          = "Ori MCP (ChatGPT)"
      launch_url    = "https://chatgpt.com"
      callback_urls = ["https://chatgpt.com/connector_platform_oauth_redirect"]
      pkce_enabled  = true
    }
    grafana = {
      name          = "Grafana"
      launch_url    = "https://grafana.home.yutakobayashi.com"
      callback_urls = ["https://grafana.home.yutakobayashi.com/login/generic_oauth"]
      pkce_enabled  = true
    }
    linkding = {
      name          = "linkding"
      launch_url    = "https://linkding.home.yutakobayashi.com"
      callback_urls = ["https://linkding.home.yutakobayashi.com/oidc/callback/"]
      pkce_enabled  = true
    }
    immich = {
      name       = "Immich"
      launch_url = "https://photos.home.yutakobayashi.com"
      callback_urls = [
        "https://photos.home.yutakobayashi.com/auth/login",
        "https://photos.home.yutakobayashi.com/user-settings",
        "app.immich:///oauth-callback",
      ]
      pkce_enabled = true
    }
    moe = {
      name       = "moe"
      launch_url = "https://moe.home.yutakobayashi.com"
      callback_urls = [
        "https://moe.home.yutakobayashi.com/auth/login",
        "https://moe.home.yutakobayashi.com/user-settings",
        "app.immich:///oauth-callback",
      ]
      pkce_enabled = true
    }
    gitea = {
      name          = "Gitea"
      launch_url    = "https://git.yutakobayashi.com"
      callback_urls = ["https://git.yutakobayashi.com/user/oauth2/pocket-id/callback"]
      # Gitea's goth OpenID Connect client does not send a PKCE challenge.
      pkce_enabled = false
    }
    nextcloud = {
      name       = "Nextcloud"
      launch_url = "https://cloud.home.yutakobayashi.com"
      callback_urls = [
        "https://cloud.home.yutakobayashi.com/apps/user_oidc/code",
        "https://cloud.home.yutakobayashi.com/index.php/apps/user_oidc/code",
      ]
      pkce_enabled = true
    }
  }
}

resource "pocketid_client" "app" {
  for_each = local.clients

  name          = each.value.name
  client_id     = each.key
  client_secret = var.client_secrets[each.key]
  callback_urls = each.value.callback_urls
  launch_url    = each.value.launch_url
  is_public     = false
  pkce_enabled  = each.value.pkce_enabled
}
