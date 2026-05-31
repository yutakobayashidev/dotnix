{ config, lib, ... }:

let
  domain = "home.yutakobayashi.com";
in
{
  sops.secrets.obsidian = {
    owner = config.services.couchdb.user;
    group = config.services.couchdb.group;
    mode = "440";
    sopsFile = ./secrets.yaml;
  };

  services.couchdb = {
    enable = true;

    bindAddress = "127.0.0.1";

    extraConfigFiles = [ config.sops.secrets.obsidian.path ];

    # https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md#configure
    extraConfig = {
      couchdb = {
        single_node = true;
        max_document_size = 50000000;
      };

      chttpd = {
        require_valid_user = true;
        max_http_request_size = 4294967296;
      };

      chttpd_auth = {
        require_valid_user = true;
        authentication_redirect = "/_utils/session.html";
      };

      httpd = {
        WWW-Authenticate = ''Basic realm="couchdb"'';
        enable_cors = true;
      };

      cors = {
        origins = "app://obsidian.md,capacitor://localhost,http://localhost";
        credentials = true;
        headers = "accept, authorization, content-type, origin, referer";
        methods = "GET,PUT,POST,HEAD,DELETE";
        max_age = 3600;
      };
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.couchdb = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`sync.${domain}`)";
      service = "couchdb";
      tls.certResolver = "letsencrypt";
    };
    services.couchdb.loadBalancer.servers = [ { url = "http://127.0.0.1:5984"; } ];
  };
}
