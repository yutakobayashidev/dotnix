{ config, ... }:

{
  services.searx = {
    enable = true;
    environmentFile = config.sops.secrets."searxng/env".path;
    settings = {
      server = {
        base_url = "https://search.home.yutakobayashi.com/";
        port = 8082;
        secret_key = "$SEARX_SECRET_KEY";
      };
      search.formats = [
        "html"
        "json"
      ];
      ui.static_use_hash = true;
    };
  };

  sops.secrets."searxng/env" = {
    sopsFile = ./secrets.yaml;
    owner = "searx";
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.searxng = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`search.home.yutakobayashi.com`)";
      service = "searxng";
      tls.certResolver = "letsencrypt";
    };
    services.searxng.loadBalancer.servers = [ { url = "http://127.0.0.1:8082"; } ];
  };
}
