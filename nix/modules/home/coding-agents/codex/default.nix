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
    model = "gpt-5.5";
    model_reasoning_effort = "medium";
    personality = "pragmatic";
    project_doc_fallback_filenames = [ "CLAUDE.md" ];
    suppress_unstable_features_warning = true;
    web_search_request = true;

    features = {
      remote_connections = true;
      remote_control = true;
      workspace_dependencies = false;
    };

    mcp_servers.deepwiki = {
      url = "https://mcp.deepwiki.com/mcp";
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
    home.packages = [ pkgs.llm-agents.codex ];

    home.sessionVariables = {
      CODEX_HOME = codexConfigDir;
    };

    home.activation.writeCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${codexConfigDir}"
      ${pkgs.coreutils}/bin/install -m 644 ${codexConfig} "${codexConfigDir}/config.toml"
    '';

    xdg.configFile."codex/AGENTS.md".source =
      config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/AGENTS.md";
  };
}
