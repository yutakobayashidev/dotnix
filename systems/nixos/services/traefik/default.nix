{ config, pkgs, ... }:

let
  domain = "home.yutakobayashi.com";
in
{
  sops.secrets.cloudflare-api-token = {
    sopsFile = ./secrets.yaml;
    owner = "traefik";
    group = "traefik";
  };

  services.traefik = {
    enable = true;

    dataDir = "/var/lib/traefik";

    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
        };
        websecure = {
          address = ":443";
        };
      };
      api.dashboard = true;

      certificatesResolvers.letsencrypt.acme = {
        email = "hi@yutakobayashi.com";
        storage = "/var/lib/traefik/acme.json";
        caServer = "https://acme-v02.api.letsencrypt.org/directory";
        dnsChallenge = {
          provider = "cloudflare";
          delayBeforeCheck = 10;
        };
      };
    };

    dynamicConfigOptions = {
      http = {
        serversTransports = {
          insecure = {
            insecureSkipVerify = true;
          };
        };
        routers = {
          gitea = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`git.${domain}`)";
            service = "gitea";
            tls = {
              certResolver = "letsencrypt";
              domains = [
                {
                  main = domain;
                  sans = [ "*.${domain}" ];
                }
              ];
            };
          };
          grafana = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`grafana.${domain}`)";
            service = "grafana";
            tls.certResolver = "letsencrypt";
          };
          nextcloud = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`cloud.${domain}`)";
            service = "nextcloud";
            tls.certResolver = "letsencrypt";
          };
          immich = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`photos.${domain}`)";
            service = "immich";
            tls.certResolver = "letsencrypt";
          };
          home-assistant = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`ha.${domain}`)";
            service = "home-assistant";
            tls.certResolver = "letsencrypt";
          };
          atuin = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`atuin.${domain}`)";
            service = "atuin";
            tls.certResolver = "letsencrypt";
          };
          archivebox = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`archive.${domain}`)";
            service = "archivebox";
            tls.certResolver = "letsencrypt";
          };
          n8n = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`n8n.${domain}`)";
            service = "n8n";
            tls.certResolver = "letsencrypt";
          };
          tv = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`tv.${domain}`)";
            service = "konomitv";
            tls.certResolver = "letsencrypt";
          };
          mirakurun = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`mirakurun.${domain}`)";
            service = "mirakurun";
            tls.certResolver = "letsencrypt";
          };
          edcb = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "Host(`edcb.${domain}`)";
            service = "edcb";
            tls.certResolver = "letsencrypt";
          };
          error-pages = {
            entryPoints = [
              "web"
              "websecure"
            ];
            rule = "HostRegexp(`.+`)";
            priority = 1;
            service = "error-pages-service";
          };
        };

        middlewares = {
          error-pages = {
            errors = {
              status = [
                "500-599"
                "404"
                "403"
              ];
              query = "/";
              service = "error-pages-service";
            };
          };
        };

        services = {
          gitea.loadBalancer.servers = [ { url = "http://localhost:3000"; } ];
          grafana.loadBalancer.servers = [
            { url = "http://localhost:${toString config.services.grafana.settings.server.http_port}"; }
          ];
          nextcloud.loadBalancer.servers = [ { url = "http://localhost:8081"; } ];
          immich.loadBalancer.servers = [ { url = "http://localhost:2283"; } ];
          home-assistant.loadBalancer.servers = [
            { url = "http://localhost:${toString config.services.home-assistant.config.http.server_port}"; }
          ];
          atuin.loadBalancer.servers = [
            { url = "http://localhost:${toString config.services.atuin.port}"; }
          ];
          archivebox.loadBalancer.servers = [ { url = "http://127.0.0.1:8000"; } ];
          n8n.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString config.services.n8n.environment.N8N_PORT}"; }
          ];
          konomitv.loadBalancer.servers = [ { url = "https://localhost:7000"; } ];
          konomitv.loadBalancer.serversTransport = "insecure";
          mirakurun.loadBalancer.servers = [ { url = "http://localhost:40772"; } ];
          edcb.loadBalancer.servers = [ { url = "http://localhost:5510"; } ];
          error-pages-service = {
            loadBalancer = {
              servers = [ { url = "http://127.0.0.1:5000"; } ];
            };
          };
        };
      };
    };
    environmentFiles = [
      config.sops.secrets.cloudflare-api-token.path
    ];
  };
}
