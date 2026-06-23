{
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "home.yutakobayashi.com";
  cfg = config.services.litellm;
  seedChatgptAuth = pkgs.writeShellScript "litellm-seed-chatgpt-auth" ''
    set -eu

    ${pkgs.coreutils}/bin/install -d -m 0700 ${cfg.stateDir}/chatgpt
    if [ -s ${cfg.stateDir}/chatgpt/auth.json ]; then
      exit 0
    fi

    umask 077
    auth_tmp="${cfg.stateDir}/chatgpt/.auth.json.tmp"
    ${pkgs.coreutils}/bin/rm -f "$auth_tmp"
    if ${pkgs.jq}/bin/jq -e '
      def litellm_auth:
        {
          access_token,
          refresh_token,
          id_token,
          expires_at,
          account_id,
        }
        | with_entries(select(.value != null));

      if has("access_token") and has("refresh_token") then
        litellm_auth
      else
        [
          .. | objects
          | select(has("access_token") and has("refresh_token"))
          | litellm_auth
        ][0]
      end
    ' "$CREDENTIALS_DIRECTORY/chatgpt-auth.json" > "$auth_tmp"; then
      ${pkgs.coreutils}/bin/install -m 0600 "$auth_tmp" ${cfg.stateDir}/chatgpt/auth.json
    fi
    ${pkgs.coreutils}/bin/rm -f "$auth_tmp"
  '';
  chatgptModels = [
    "chatgpt/gpt-5.4"
    "chatgpt/gpt-5.4-pro"
    "chatgpt/gpt-5.3-codex"
    "chatgpt/gpt-5.3-codex-spark"
    "chatgpt/gpt-5.3-instant"
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
      seedChatgptAuth
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
