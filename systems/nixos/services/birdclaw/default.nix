{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  domain = "birdclaw.home.yutakobayashi.com";
  port = 3005;
  birdclawConfig = {
    mentions = {
      dataSource = "bird";
      birdCommand = lib.getExe pkgs.bird;
    };
    backup = {
      repoPath = "/home/yuta/ghq/git.yutakobayashi.com/yuta/twitter-archive";
      remote = "https://git.yutakobayashi.com/yuta/twitter-archive";
      autoSync = true;
      staleAfterSeconds = 900;
    };
  };
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
    environmentFiles = [ config.sops.secrets."birdclaw-discord-webhook-url".path ];

    config = birdclawConfig;

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
        intervalSeconds = 10800;
        windowHours = 3;
        language = "ja";
        maxTweets = 700;
      };
    };
  };

  systemd.user.timers = {
    birdclaw-account-sync.timerConfig.OnActiveSec = "1m";
    birdclaw-bookmark-sync.timerConfig.OnActiveSec = "1m";
    birdclaw-digest.timerConfig.OnActiveSec = "1m";
  };

  systemd.user.services = {
    birdclaw = {
      path = [ pkgs.git ];
      environment = {
        BIRDCLAW_BIRD_COMMAND = lib.getExe pkgs.bird;
        OPENAI_API_KEY = "sk-proxy";
        BIRDCLAW_OPENAI_BASE_URL = "https://litellm.home.yutakobayashi.com/v1";
        BIRDCLAW_AI_MODEL = "deepseek-analyst";
        BIRDCLAW_OPENAI_MODEL = "deepseek-inbox";
        TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";
      };
    };

    birdclaw-account-sync = {
      path = [ pkgs.git ];
      environment = {
        BIRDCLAW_BIRD_COMMAND = lib.getExe pkgs.bird;
        TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";
      };
    };

    birdclaw-bookmark-sync = {
      path = [ pkgs.git ];
      environment = {
        BIRDCLAW_BIRD_COMMAND = lib.getExe pkgs.bird;
        TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";
      };
    };

    birdclaw-digest = {
      path = [ pkgs.git ];
      environment = {
        BIRDCLAW_BIRD_COMMAND = lib.getExe pkgs.bird;
        TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";
        OPENAI_API_KEY = "sk-proxy";
        BIRDCLAW_OPENAI_BASE_URL = "https://litellm.home.yutakobayashi.com/v1";
        BIRDCLAW_AI_MODEL = "deepseek-analyst";
      };
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
