_:

{
  flake.modules.homeManager."codex" =
    {
      inputs,
      lib,
      config,
      pkgs,
      dotfilesDir,
      osConfig,
      ...
    }:

    let
      cfg = config.my.programs.codex;
      codexConfigDir =
        if config.home.preferXdgDirectories then
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/codex"
        else
          ".codex";
      codexDotfilesDir = "${dotfilesDir}/codex";
      sessionTtsRoot = "${codexDotfilesDir}/session-tts";
      sessionTtsSkills = ../../../../codex/session-tts/skills;
      sessionTtsHome = "${config.xdg.stateHome}/session-tts";
      mkCommandHook = command: {
        type = "command";
        inherit command;
      };
      mkSessionTtsHook =
        script: args:
        mkCommandHook (
          "SESSION_TTS_HOME=${lib.escapeShellArg sessionTtsHome} "
          + "${lib.getExe pkgs.bash} ${lib.escapeShellArg "${sessionTtsRoot}/scripts/${script}"}"
          + lib.optionalString (args != [ ]) " ${lib.escapeShellArgs args}"
        );
      mkHookGroup = hooks: [
        {
          matcher = "";
          inherit hooks;
        }
      ];
      codexHooks = {
        hooks = {
          SessionStart = mkHookGroup [ (mkSessionTtsHook "session-on.sh" [ ]) ];
          Stop = mkHookGroup [ (mkSessionTtsHook "dispatch.sh" [ ]) ];
          UserPromptSubmit = mkHookGroup [ (mkSessionTtsHook "remind-say.sh" [ "prompt" ]) ];
          SubagentStart = mkHookGroup [ (mkSessionTtsHook "remind-say.sh" [ "subagent" ]) ];
        };
      };
      otelExporter =
        signal:
        if cfg.telemetry.enable then
          (
            if cfg.telemetry.protocol == "grpc" then
              {
                "otlp-grpc".endpoint = cfg.telemetry.endpoint;
              }
            else
              {
                "otlp-http" = {
                  endpoint = "${cfg.telemetry.endpoint}/v1/${signal}";
                  protocol = "binary";
                };
              }
          )
        else
          "none";
      settings = {
        approval_policy = "on-request";
        approvals_reviewer = "auto_review";
        model_reasoning_summary = "concise";
        model_verbosity = "low";
        personality = "pragmatic";
        project_doc_fallback_filenames = [ "CLAUDE.md" ];
        suppress_unstable_features_warning = true;
        web_search = "live";
        oss_provider = "lmstudio";

        apps."asdk_app_6a60662bf1888191a2da3c0b2f811534".enabled = false;

        features = {
          hooks = true;
          reasoning_effort_override = true;
          remote_control = true;
          workspace_dependencies = false;
        };

        default_permissions = "project";

        permissions.project = {
          extends = ":workspace";
          workspace_roots = lib.optionalAttrs cfg.desktopIntegration {
            "${sessionTtsHome}" = true;
          };
          network = {
            enabled = true;
            domains = {
              "aivisspeech.home.yutakobayashi.com" = "allow";
              "search.home.yutakobayashi.com" = "allow";
              "localhost" = "allow";
              "127.0.0.1" = "allow";
            };
          };
        };

        otel = {
          environment = "${cfg.telemetry.environment}";
          exporter = otelExporter "logs";
          metrics_exporter = otelExporter "metrics";
          trace_exporter = otelExporter "traces";
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
    in
    {
      options.my.programs.codex = {
        enable = lib.mkEnableOption "Codex";
        acp.enable = lib.mkEnableOption "Codex ACP adapter";

        desktopIntegration = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable desktop attention hooks, speech playback, and transcription tools.";
        };

        telemetry = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Codex OTLP telemetry.";
          };

          protocol = lib.mkOption {
            type = lib.types.enum [
              "grpc"
              "http/protobuf"
            ];
            default = if osConfig.my.services.agentTelemetry.enable or false then "grpc" else "http/protobuf";
            description = "Transport for the configured OTLP endpoint.";
          };

          endpoint = lib.mkOption {
            type = lib.types.str;
            default =
              if osConfig.my.services.agentTelemetry.enable or false then
                "http://127.0.0.1:4317"
              else
                "http://B450M-Pro4.tail29d068.ts.net:4318";
            description = "OTLP base endpoint for Codex logs, metrics, and traces.";
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
        programs.codex = {
          enable = true;
          enableMcpIntegration = true;
          package = pkgs.llm-agents.codex;
          mutableSettings = true;
          inherit settings;
          hooks = lib.mkIf cfg.desktopIntegration codexHooks.hooks;
        };

        programs.agent-skills = lib.mkIf cfg.desktopIntegration {
          sources.session-tts.path = sessionTtsSkills;

          skills.explicit = {
            session-tts = {
              from = "session-tts";
              path = "tts";
              rewriteCommands = false;
              transform =
                { original, ... }:
                builtins.replaceStrings
                  [ "session-tts-tts " ]
                  [
                    "${lib.getExe pkgs.bash} ${lib.escapeShellArg "${sessionTtsRoot}/skills/tts/tts.sh"} "
                  ]
                  original;
            };

            session-tts-volume = {
              from = "session-tts";
              path = "volume";
              rewriteCommands = false;
              transform =
                { original, ... }:
                builtins.replaceStrings
                  [ "session-tts-volume " ]
                  [
                    "${lib.getExe pkgs.bash} ${lib.escapeShellArg "${sessionTtsRoot}/skills/volume/volume.sh"} "
                  ]
                  original;
            };
          };
        };

        home = {
          packages = [
            pkgs.llm-agents.codex-auth
          ]
          ++ lib.optionals cfg.desktopIntegration [
            pkgs.session-tts
            inputs.codex-transcribe.packages.${pkgs.stdenv.hostPlatform.system}.default
          ]
          ++ lib.optional cfg.acp.enable (
            pkgs.llm-agents.codex-acp.override { codex = pkgs.llm-agents.codex; }
          );

          file = {
            "${codexConfigDir}/rules".source = config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/rules";
            "${codexConfigDir}/AGENTS.md".source =
              config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/AGENTS.md";
          };
        };
      };
    };
}
