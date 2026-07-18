{
  lib,
  config,
  pkgs,
  dotfilesDir,
  osConfig,
  ...
}:

let
  cfg = config.my.programs.codex;
  codexConfigDir = "${config.xdg.configHome}/codex";
  codexDotfilesDir = "${dotfilesDir}/codex";
  tomlFormat = pkgs.formats.toml { };
  otelExporter =
    if cfg.telemetry.enable then
      {
        "otlp-http" = {
          endpoint = cfg.telemetry.endpoint;
          protocol = "binary";
        };
      }
    else
      "none";
  settings = {
    approval_policy = "on-request";
    default_mode_request_user_input = true;
    model = "gpt-5.6-sol";
    model_reasoning_effort = "medium";
    model_reasoning_summary = "concise";
    model_verbosity = "low";
    personality = "pragmatic";
    project_doc_fallback_filenames = [ "CLAUDE.md" ];
    suppress_unstable_features_warning = true;
    web_search_request = true;
    oss_provider = "lmstudio";

    features = {
      remote_connections = true;
      remote_control = true;
      workspace_dependencies = false;
    };

    default_permissions = "project";

    permissions.project = {
      extends = ":workspace";
      workspace_roots."${codexConfigDir}/session-tts" = true;
      network = {
        enabled = true;
        domains = {
          "aivisspeech.home.yutakobayashi.com" = "allow";
          "junction-mcp-up7swxs6gq-an.a.run.app" = "allow";
          "8.232.48.91" = "allow";
          "localhost" = "allow";
          "127.0.0.1" = "allow";
        };
      };
    };

    mcp_servers.deepwiki = {
      url = "https://mcp.deepwiki.com/mcp";
    };

    mcp_servers.junction = {
      url = "https://junction-mcp-up7swxs6gq-an.a.run.app/mcp";
      oauth_resource = "https://junction-mcp-up7swxs6gq-an.a.run.app/mcp";
    };

    otel = {
      environment = "${cfg.telemetry.environment}";
      exporter = otelExporter;
      log_user_prompt = cfg.telemetry.logUserPrompts;
    };

    plugins = {
      "github@openai-curated".enabled = true;
      "browser-use@openai-bundled".enabled = true;
      "documents@openai-primary-runtime".enabled = true;
      "spreadsheets@openai-primary-runtime".enabled = true;
      "presentations@openai-primary-runtime".enabled = true;
      "session-tts@personal".enabled = true;
    };
  };
  codexConfig = tomlFormat.generate "codex-config" settings;
in
{
  options.my.programs.codex = {
    enable = lib.mkEnableOption "Codex";

    telemetry = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Codex OTLP telemetry.";
      };

      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "http://B450M-Pro4.tail29d068.ts.net:4318/v1/logs";
        description = "OTLP HTTP endpoint for Codex telemetry.";
      };

      environment = lib.mkOption {
        type = lib.types.str;
        default = "home-${osConfig.networking.hostName or "unknown"}";
        description = "OTel environment tag for Codex telemetry.";
      };

      logUserPrompts = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Forward raw user prompts in Codex telemetry.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        pkgs.llm-agents.codex
        pkgs.session-tts-codex
      ];

      sessionVariables = {
        CODEX_HOME = codexConfigDir;
      };

      activation = {
        writeCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "${codexConfigDir}"
          mkdir -p "${codexConfigDir}/session-tts"
          ${pkgs.coreutils}/bin/install -m 644 ${codexConfig} "${codexConfigDir}/config.toml"
        '';

        # Global plugin: symlink session-tts under ~/plugins/ so Codex
        # discovers the plugin from the personal marketplace in every repo.
        installSessionTtsPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/plugins"
          ln -sfn "${codexDotfilesDir}/session-tts" "$HOME/plugins/session-tts"
        '';
      };

      file = {
        ".codex/rules".source = config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/rules";
        ".agents/plugins/marketplace.json".text = builtins.toJSON {
          name = "personal";
          plugins = [
            {
              name = "session-tts";
              source = {
                source = "local";
                path = "./plugins/session-tts";
              };
              policy = {
                installation = "AVAILABLE";
                authentication = "ON_INSTALL";
              };
              category = "Productivity";
            }
          ];
        };
      };
    };

    xdg.configFile."codex/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/AGENTS.md";
  };
}
