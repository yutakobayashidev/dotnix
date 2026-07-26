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
      inherit (pkgs.stdenv.hostPlatform) isLinux;
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
          PermissionRequest = mkHookGroup (
            lib.optional isLinux {
              type = "command";
              command = "NIRI_BIN=${lib.getExe pkgs.niri} ${lib.getExe pkgs.bash} ${lib.escapeShellArg "${codexDotfilesDir}/hooks/focus-approval.sh"}";
              timeout = 5;
            }
            ++ [ (mkSessionTtsHook "notify-permission.sh" [ ]) ]
          );
          UserPromptSubmit = mkHookGroup [ (mkSessionTtsHook "remind-say.sh" [ "prompt" ]) ];
          SubagentStart = mkHookGroup [ (mkSessionTtsHook "remind-say.sh" [ "subagent" ]) ];
        };
      };
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
          hooks = true;
          remote_connections = true;
          remote_control = true;
          workspace_dependencies = false;
        };

        default_permissions = "project";

        permissions.project = {
          extends = ":workspace";
          workspace_roots."${sessionTtsHome}" = true;
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

        mcp_servers =
          lib.optionalAttrs (config.my.programs.mcp.enable && config.my.programs.mcp.ghidra.enable)
            {
              ghidra = {
                inherit (config.programs.mcp.servers.ghidra) command args;
                default_tools_approval_mode = "approve";
                startup_timeout_sec = 300;
              };
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
      rawSettings =
        if config.programs.codex.settings == null then { } else config.programs.codex.settings;
      baseSettings = lib.removeAttrs rawSettings [ "mcp_servers" ];
      settingMcpServers = rawSettings.mcp_servers or { };
      sharedMcpServers = lib.mapAttrs (
        name: server:
        lib.hm.mcp.transformMcpServer {
          inherit server;
          exclude = [
            "headers"
            "type"
          ];
          extraTransforms = [
            (s: s // lib.optionalAttrs (s.headers or { } != { }) { http_headers = s.headers; })
            lib.hm.mcp.addType
            (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
          ];
        }
      ) config.programs.mcp.servers;
      inlineConfig = inputs.mcp-servers-nix.lib.mkConfig pkgs {
        flavor = "codex";
        format = "toml-inline";
        fileName = "codex-inline-config.toml";
        settings = baseSettings // {
          servers = sharedMcpServers // settingMcpServers;
        };
      };
      codexWrapper =
        (pkgs.writeShellApplication {
          name = "codex";
          text = ''
            export SESSION_TTS_HOME=${lib.escapeShellArg sessionTtsHome}
            export CODEX_NIRI_WINDOW_ID=
            ${lib.optionalString isLinux ''
              if [[ ''${HERDR_ENV:-} != 1 && -n ''${NIRI_SOCKET:-} ]]; then
                if window_id=$(${lib.getExe pkgs.niri} msg -j focused-window 2>/dev/null \
                  | ${lib.getExe pkgs.jq} -r \
                    'select(.app_id == "com.mitchellh.ghostty") | .id // empty') \
                  && [[ $window_id =~ ^[0-9]+$ ]]; then
                  export CODEX_NIRI_WINDOW_ID=$window_id
                fi
              fi
            ''}

            config_args=()
            while IFS= read -r config; do
              config_args+=(--config "$config")
            done < ${inlineConfig}
            exec ${lib.getExe pkgs.llm-agents.codex} "''${config_args[@]}" "$@"
          '';
        }).overrideAttrs
          {
            inherit (pkgs.llm-agents.codex) version;
          };
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
        programs.codex = {
          enable = true;
          enableMcpIntegration = true;
          package = codexWrapper;
          inherit settings;
        };

        programs.agent-skills = {
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
          packages = [ pkgs.session-tts ];

          file = {
            # Codex updates its user config at runtime, so only immutable
            # defaults are injected by the wrapper.
            "${codexConfigDir}/config.toml".enable = false;
            "${codexConfigDir}/rules".source = config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/rules";
            "${codexConfigDir}/AGENTS.md".source =
              config.lib.file.mkOutOfStoreSymlink "${codexDotfilesDir}/AGENTS.md";
            "${codexConfigDir}/hooks.json".text = builtins.toJSON codexHooks;
          };
        };
      };
    };
}
