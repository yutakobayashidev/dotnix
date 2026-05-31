{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  domain = "home.yutakobayashi.com";
  niks3Port = "5751";
  serverDomain = "cache.${domain}";
  cacheDomain = "cache.${domain}";
in
{
  imports = [ inputs.niks3.nixosModules.niks3 ];

  services.niks3 = {
    enable = true;
    httpAddr = "127.0.0.1:${niks3Port}";

    database.createLocally = true;

    s3 = {
      # FIXME: Replace with your own R2/S3 endpoint, bucket, and region
      endpoint = "example.r2.cloudflarestorage.com";
      bucket = "nix-cache";
      region = "auto";
      useSSL = true;
      accessKeyFile = config.sops.secrets.niks3-s3-access-key.path;
      secretKeyFile = config.sops.secrets.niks3-s3-secret-key.path;
    };

    apiTokenFile = config.sops.secrets.niks3-api-token.path;
    signKeyFiles = [ config.sops.secrets.niks3-signing-key.path ];

    cacheUrl = "https://${cacheDomain}";

    gc.olderThan = "168h";
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        niks3 = {
          entryPoints = [
            "web"
            "websecure"
          ];
          rule = "Host(`${serverDomain}`)";
          service = "niks3";
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
      };

      services.niks3.loadBalancer.servers = [ { url = "http://127.0.0.1:${niks3Port}"; } ];
    };
  };

  sops.secrets = {
    niks3-api-token = {
      sopsFile = ./secrets.yaml;
      owner = config.services.niks3.user;
    };
    niks3-signing-key = {
      sopsFile = ./secrets.yaml;
      owner = config.services.niks3.user;
    };
    niks3-s3-access-key = {
      sopsFile = ./secrets.yaml;
      owner = config.services.niks3.user;
    };
    niks3-s3-secret-key = {
      sopsFile = ./secrets.yaml;
      owner = config.services.niks3.user;
    };
  };
}
