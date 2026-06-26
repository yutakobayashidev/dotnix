{
  config,
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

  sops.secrets."birdclaw-discord-webhook-url" = {
    sopsFile = ../../B450M-Pro4/secrets.yaml;
    owner = "yuta";
    mode = "0600";
  };

  services.birdclaw = {
    enable = true;
    host = "127.0.0.1";
    inherit port;
    allowRemoteWeb = true;

    config = {
      mentions = {
        dataSource = "bird";
        birdCommand = lib.getExe bird;
      };
      discord.webhookUrl = config.sops.placeholder."birdclaw-discord-webhook-url";
    };

    jobs = {
      accountSync = {
        enable = true;
        account = "acct_primary";
        intervalSeconds = 900;
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

      digest = {
        enable = true;
        intervalSeconds = 3600;
        windowHours = 6;
        language = "ja";
      };
    };
  };

  systemd.user.services = {
    birdclaw.environment = {
      BIRDCLAW_BIRD_COMMAND = lib.getExe bird;
      OPENAI_API_KEY = "sk-proxy";
      OPENAI_BASE_URL = "https://litellm.home.yutakobayashi.com";
      BIRDCLAW_AI_MODEL = "deepseek-analyst";
      BIRDCLAW_OPENAI_MODEL = "deepseek-inbox";
      TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";
    };

    birdclaw-account-sync.environment = {
      BIRDCLAW_BIRD_COMMAND = lib.getExe bird;
      TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";
    };

    birdclaw-bookmark-sync.environment = {
      BIRDCLAW_BIRD_COMMAND = lib.getExe bird;
      TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";
    };

    birdclaw-digest.environment = {
      BIRDCLAW_BIRD_COMMAND = lib.getExe bird;
      TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";
      OPENAI_API_KEY = "sk-proxy";
      OPENAI_BASE_URL = "https://litellm.home.yutakobayashi.com";
      BIRDCLAW_AI_MODEL = "deepseek-analyst";
    };
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
