{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  bird = inputs.bird.packages.${pkgs.stdenv.hostPlatform.system}.bird;
  domain = "birdclaw.home.yutakobayashi.com";
  port = 3005;
in

{
  imports = [ inputs.birdclaw.nixosModules.birdclaw ];

  services.birdclaw = {
    enable = true;
    host = "127.0.0.1";
    inherit port;
    allowRemoteWeb = true;

    config = {
      mentions = {
        dataSource = "bird";
      };
    };

    jobs = {
      accountSync = {
        enable = true;
        account = "acct_openclaw";
        intervalSeconds = 1800;
        steps = [
          "timeline"
          "mentions"
          "likes"
        ];
        maxPages = 3;
      };

      bookmarkSync = {
        enable = true;
        intervalSeconds = 10800;
        mode = "auto";
        maxPages = 5;
      };
    };
  };

  systemd.user.services.birdclaw.environment = {
    BIRDCLAW_BIRD_COMMAND = lib.getExe bird;
    OPENAI_API_KEY = "sk-proxy";
    OPENAI_BASE_URL = "https://litellm.home.yutakobayashi.com";
    BIRDCLAW_AI_MODEL = "deepseek-analyst";
    BIRDCLAW_OPENAI_MODEL = "deepseek-inbox";
    TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.birdclaw = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`${domain}`)";
      service = "birdclaw";
      tls.certResolver = "letsencrypt";
    };
    services.birdclaw.loadBalancer.servers = [
      { url = "http://127.0.0.1:${toString port}"; }
    ];
  };
}
