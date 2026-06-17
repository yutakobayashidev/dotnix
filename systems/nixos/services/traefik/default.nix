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
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
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

      providers.docker = {
        endpoint = "unix:///run/podman/podman.sock";
        exposedByDefault = false;
      };
    };

    dynamicConfigOptions.http = {
      serversTransports.insecure = {
        insecureSkipVerify = true;
      };

      routers = {
        error-pages = {
          entryPoints = [
            "web"
            "websecure"
          ];
          rule = "HostRegexp(`.+`)";
          priority = 1;
          service = "cloudflare-error-page@docker";
          middlewares = [ "error-pages" ];
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

      };

      middlewares.error-pages = {
        errors = {
          status = [
            "500-599"
            "404"
            "403"
          ];
          query = "/{status}.html";
          service = "cloudflare-error-page@docker";
        };
      };

      services = {
        konomitv = {
          loadBalancer = {
            servers = [ { url = "https://localhost:7000"; } ];
            serversTransport = "insecure";
          };
        };
        mirakurun.loadBalancer.servers = [ { url = "http://localhost:40772"; } ];
        edcb.loadBalancer.servers = [ { url = "http://localhost:5510"; } ];
      };
    };
    environmentFiles = [
      config.sops.secrets.cloudflare-api-token.path
    ];
  };

  users.users.traefik.extraGroups = [ "podman" ];
}
