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
  # Verified against this account's Codex model catalog on 2026-11-07.
  chatgptModels = [
    "chatgpt/gpt-6.1-sol"
    "chatgpt/gpt-6.1-terra"
    "chatgpt/gpt-6-astra"
    "chatgpt/gpt-6-sol"
    "chatgpt/gpt-6-luna"
    "chatgpt/gpt-5.6-sol"
    "chatgpt/gpt-5.6-terra"
    "chatgpt/gpt-5.6-luna"
  ];
  mkModel = name: context: {
    model_name = name;
    model_info = {
      inherit context;
      supportsReasoning = true;
    };
    litellm_params = {
      # Go translates every text model to the OpenAI-compatible API.
      model = "openai/${name}";
      api_base = "https://opencode.ai/inference/go/openai/v1";
      api_key = "os.environ/OPENCODE_GO_KEY";
      drop_params = true;
      stream = false;
    };
  };
  # Existing model families, refreshed from the public Go catalog on 2026-11-07:
  # https://opencode.ai/inference/go/v1/models
  opencodeModels = [
    (mkModel "deepseek-v4-pro" 1000000)
    (mkModel "deepseek-v4.1-flash" 1000000)
    (mkModel "glm-5.2" 1000000)
    (mkModel "glm-5.3" 1000000)
    (mkModel "glm-5.3-flash" 1000000)
    (mkModel "hy3" 256000)
    (mkModel "hy4" 1048576)
    (mkModel "hy4-preview" 1024000)
    (mkModel "kimi-k2.7-code" 262144)
    (mkModel "kimi-k3" 1048576)
    (mkModel "kimi-k3.1-pro" 1048576)
    (mkModel "mimo-v2.6-flash" 1048576)
    (mkModel "mimo-v2.6-pro" 1048576)
    (mkModel "minimax-m3" 1000000)
    (mkModel "minimax-m3.1-flash" 1000000)
    (mkModel "qwen3.7-plus" 1000000)
    (mkModel "qwen3.8-flash" 1000000)
    (mkModel "qwen3.8-max" 1000000)
  ];
in
{
  sops = {
    secrets."litellm/chatgpt-auth-json" = {
      sopsFile = ./auth.json;
      format = "binary";
    };
    secrets."litellm/opencode-go-key" = {
      sopsFile = ./secrets.yaml;
    };
    templates."litellm.env" = {
      content = ''
        OPENCODE_GO_KEY=${config.sops.placeholder."litellm/opencode-go-key"}
      '';
      mode = "0400";
    };
  };

  services.litellm = {
    enable = true;
    port = 8317;
    environment.CHATGPT_TOKEN_DIR = "${cfg.stateDir}/chatgpt";
    settings = {
      model_list =
        (map (model: {
          model_name = model;
          model_info.mode = "responses";
          litellm_params.model = model;
        }) chatgptModels)
        ++ opencodeModels;
      litellm_settings = {
        # Preserve the caller's per-conversation OpenCode session header.
        model_group_settings.forward_client_headers_to_llm_api = map (
          model: model.model_name
        ) opencodeModels;
        num_retries = 1;
        drop_params = true;
        reasoning_auto_summary = true;
        fallbacks = [
          {
            deepseek-analyst = [
              "deepseek-v4.1-flash"
              "chatgpt/gpt-6.1-sol"
            ];
          }
          {
            deepseek-inbox = [
              "deepseek-v4-pro"
              "chatgpt/gpt-6-astra"
            ];
          }
        ];
        default_fallbacks = [
          "deepseek-v4-pro"
          "deepseek-v4.1-flash"
          "chatgpt/gpt-6.1-sol"
        ];
      };
      router_settings = {
        model_group_alias = {
          "deepseek-analyst" = "deepseek-v4-pro";
          "deepseek-inbox" = "deepseek-v4.1-flash";
        };
      };
      general_settings.master_key = "sk-proxy";
    };
  };

  systemd.services.litellm.serviceConfig = {
    EnvironmentFile = config.sops.templates."litellm.env".path;
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
