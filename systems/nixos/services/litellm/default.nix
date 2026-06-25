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
  mkModel =
    {
      name,
      id,
      stream ? false,
      needsMessagesEndpoint ? false,
      context ? 204800,
      ...
    }:
    {
      model_name = name;
      model_info = {
        context = context;
      };
      litellm_params = {
        model = id;
        api_base = "https://opencode.ai/zen/go/v1/${
          if needsMessagesEndpoint then "messages" else "chat/completions"
        }";
        api_key = "os.environ/OPENCODE_GO_KEY";
        drop_params = true;
        inherit stream;
      };
    };
  opencodeModels = [
    # Minimax
    (mkModel {
      name = "minimax-m3";
      id = "anthropic/minimax-m3";
    })
    (mkModel {
      name = "minimax-m2.7";
      id = "anthropic/minimax-m2.7";
    })
    (mkModel {
      name = "minimax-m2.5";
      id = "anthropic/minimax-m2.5";
    })
    # GLM
    (mkModel {
      name = "glm-5.2";
      id = "zai/glm-5.2";
    })
    (mkModel {
      name = "glm-5.1";
      id = "zai/glm-5.1";
    })
    (mkModel {
      name = "glm-5";
      id = "zai/glm-5";
    })
    # KIMI
    (mkModel {
      name = "kimi-k2.7-code";
      id = "moonshot/kimi-k2.7-code";
      context = 262144;
    })
    (mkModel {
      name = "kimi-k2.6";
      id = "moonshot/kimi-k2.6";
      context = 262144;
    })
    (mkModel {
      name = "kimi-k2.5";
      id = "moonshot/kimi-k2.5";
      context = 262144;
    })
    # MIMO
    (mkModel {
      name = "mimo-v2-pro";
      id = "openai/mimo-v2-pro";
      context = 1048576;
    })
    (mkModel {
      name = "mimo-v2-omni";
      id = "openai/mimo-v2-omni";
      context = 262144;
    })
    (mkModel {
      name = "mimo-v2.5-pro";
      id = "openai/mimo-v2.5-pro";
      context = 1048576;
    })
    (mkModel {
      name = "mimo-v2.5";
      id = "openai/mimo-v2.5";
      context = 262144;
    })
    # Qwen
    (mkModel {
      name = "qwen3.7-max";
      id = "alibaba/qwen3.7-max";
      context = 1048576;
    })
    (mkModel {
      name = "qwen3.7-plus";
      id = "alibaba/qwen3.7-plus";
      context = 262144;
    })
    (mkModel {
      name = "qwen3.6-plus";
      id = "alibaba/qwen3.6-plus";
      context = 1048576;
    })
    (mkModel {
      name = "qwen3.5-plus";
      id = "alibaba/qwen3.5-plus";
      context = 262144;
    })
    # DeepSeek
    (mkModel {
      name = "deepseek-v4-pro";
      id = "deepseek/deepseek-v4-pro";
      context = 1048576;
    })
    (mkModel {
      name = "deepseek-v4-flash";
      id = "deepseek/deepseek-v4-flash";
      context = 1048576;
    })
    # HY3
    (mkModel {
      name = "hy3-preview";
      id = "openai/hy3-preview";
    })
  ];
in
{
  sops.secrets."litellm/chatgpt-auth-json" = {
    sopsFile = ./auth.json;
    format = "binary";
  };
  sops.secrets."litellm/opencode-go-key" = {
    sopsFile = ./secrets.yaml;
  };
  sops.templates."litellm.env" = {
    content = ''
      OPENCODE_GO_KEY=${config.sops.placeholder."litellm/opencode-go-key"}
    '';
    mode = "0400";
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
      litellm_settings.drop_params = true;
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
