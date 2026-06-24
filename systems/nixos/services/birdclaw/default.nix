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
  imports = [
    inputs.nur-packages.nixosModules.birdclaw
  ];

  services.birdclaw = {
    enable = true;
    host = "127.0.0.1";
    inherit port;
  };

  systemd.services.birdclaw.environment = {
    BIRDCLAW_BIRD_COMMAND = lib.getExe bird;
    OPENAI_API_KEY = "sk-proxy";
    OPENAI_BASE_URL = "https://litellm.home.yutakobayashi.com";
    BIRDCLAW_AI_MODEL = "chatgpt/gpt-5.4";
    BIRDCLAW_OPENAI_MODEL = "chatgpt/gpt-5.4";
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
