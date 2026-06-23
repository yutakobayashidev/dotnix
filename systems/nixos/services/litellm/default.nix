{
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "home.yutakobayashi.com";
  cfg = config.services.litellm;
  installChatgptAuth = pkgs.writeShellScript "litellm-install-chatgpt-auth" ''
    set -eu

    ${pkgs.coreutils}/bin/install -d -m 0700 ${cfg.stateDir}/chatgpt
    if [ ! -s ${cfg.stateDir}/chatgpt/auth.json ]; then
      ${pkgs.coreutils}/bin/install -m 0600 \
        "$CREDENTIALS_DIRECTORY/chatgpt-auth.json" \
        ${cfg.stateDir}/chatgpt/auth.json
    fi
  '';
  chatgptModels = [
    "chatgpt/gpt-5.5"
    "chatgpt/gpt-5.4"
    "chatgpt/gpt-5.4-pro"
    "chatgpt/gpt-5.3-codex-spark"
    "chatgpt/gpt-5.3-chat-latest"
  ];
in
{
  sops.secrets."litellm/chatgpt-auth-json" = {
    sopsFile = ./auth.json;
    format = "binary";
  };

  services.litellm = {
    enable = true;
    port = 8317;
    environment.CHATGPT_TOKEN_DIR = "${cfg.stateDir}/chatgpt";
    settings = {
      model_list = map (model: {
        model_name = model;
        model_info.mode = "responses";
        litellm_params.model = model;
      }) chatgptModels;
      litellm_settings.drop_params = true;
      general_settings.master_key = "sk-proxy";
    };
  };

  systemd.services.litellm.serviceConfig = {
    LoadCredential = [
      "chatgpt-auth.json:${config.sops.secrets."litellm/chatgpt-auth-json".path}"
    ];
    ExecStartPre = lib.mkAfter [
      installChatgptAuth
    ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.litellm = {
      entryPoints = [
        "web"
        "websecure"
      ];
      rule = "Host(`litellm.${domain}`)";
      service = "litellm";
      tls.certResolver = "letsencrypt";
    };
    services.litellm.loadBalancer.servers = [
      { url = "http://${cfg.host}:${toString cfg.port}"; }
    ];
  };
}
