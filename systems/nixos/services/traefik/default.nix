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
    };

    dynamicConfigOptions.http = {
      routers = {
        error-pages = {
          entryPoints = [
            "web"
            "websecure"
          ];
          rule = "HostRegexp(`.+`)";
          priority = 1;
          service = "error-pages-service";
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
        tw = {
          entryPoints = [
            "web"
            "websecure"
          ];
          rule = "Host(`tw.${domain}`)";
          service = "tw";
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
          query = "/";
          service = "error-pages-service";
        };
      };

      services = {
        konomitv.loadBalancer.servers = [ { url = "https://localhost:7000"; } ];
        mirakurun.loadBalancer.servers = [ { url = "http://localhost:40772"; } ];
        edcb.loadBalancer.servers = [ { url = "http://localhost:5510"; } ];
        tw.loadBalancer.servers = [ { url = "http://localhost:3090"; } ];
        error-pages-service.loadBalancer.servers = [ { url = "http://127.0.0.1:5000"; } ];
      };
    };
    environmentFiles = [
      config.sops.secrets.cloudflare-api-token.path
    ];
  };
}
