{
  lib,
  config,
  pkgs,
  dotfilesDir,
  osConfig,
  ...
}:

let
  cfg = config.my.programs.claude-code;
  claudeConfigDir = "${config.xdg.configHome}/claude";
  claudeDotfilesDir = "${dotfilesDir}/claude";
  inherit (config.home) homeDirectory;

  jq = lib.getExe pkgs.jq;
  boolString = value: if value then "1" else "0";
  telemetryResourceAttributes = cfg.telemetry.resourceAttributes // {
    account_name = config.home.username;
    "service.name" = "claude-code";
    "host.name" = osConfig.networking.hostName or "unknown";
  };
  telemetryEnv = lib.optionalAttrs cfg.telemetry.enable {
    OTEL_METRICS_EXPORTER = "otlp";
    OTEL_LOGS_EXPORTER = "otlp";
    OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
    OTEL_EXPORTER_OTLP_ENDPOINT = cfg.telemetry.endpoint;
    OTEL_METRIC_EXPORT_INTERVAL = "10000";
    OTEL_LOG_USER_PROMPTS = boolString cfg.telemetry.logUserPrompts;
    OTEL_RESOURCE_ATTRIBUTES = lib.concatStringsSep "," (
      lib.mapAttrsToList (name: value: "${name}=${value}") telemetryResourceAttributes
    );
  };

  terminal-notifier =
    if pkgs.stdenv.isDarwin then lib.getExe' pkgs.terminal-notifier "terminal-notifier" else "";

  baseSettings = {
    "$schema" = "https://json.schemastore.org/claude-code-settings.json";

    env = {
      ANTHROPIC_BASE_URL = "https://headroom.home.yutakobayashi.com";
      BASH_DEFAULT_TIMEOUT_MS = "300000";
      BASH_MAX_TIMEOUT_MS = "1200000";
      CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
      MAX_MCP_OUTPUT_TOKENS = "50000";
      MCP_TOOL_TIMEOUT = "120000";
      CLAUDE_CODE_MAX_OUTPUT_TOKENS = "32000";
      CLAUDE_CODE_AUTO_CONNECT_IDE = "0";
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      CLAUDE_CODE_ENABLE_TELEMETRY = boolString cfg.telemetry.enable;
      CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL = "1";
      CLAUDE_CODE_IDE_SKIP_VALID_CHECK = "1";
      DISABLE_AUTOUPDATER = "1";
      DISABLE_ERROR_REPORTING = "1";
      DISABLE_INTERLEAVED_THINKING = "1";
      DISABLE_MICROCOMPACT = "1";
      DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1";
      DISABLE_TELEMETRY = boolString (!cfg.telemetry.enable);
      CLAUDE_CODE_EFFORT_LEVEL = "max";
      ENABLE_EXPERIMENTAL_MCP_CLI = "false";
      ENABLE_TOOL_SEARCH = "true";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      IS_DEMO = "1";
    }
    // telemetryEnv;

    enabledPlugins = {
      "gopls-lsp@claude-plugins-official" = true;
    };

    cleanupPeriodDays = 876000;
    includeCoAuthoredBy = false;
    language = "Japanese";
    alwaysThinkingEnabled = true;
    autoMemoryEnabled = false;
    useAutoModeDuringPlan = true;
    skipAutoPermissionPrompt = true;
    skipDangerousModePermissionPrompt = true;
    enableAllProjectMcpServers = true;
    plansDirectory = "./plans";

    statusLine = {
      type = "command";
      command = "ccusage statusline";
      padding = 0;
    };

    permissions = {
      defaultMode = "auto";
      deny = [
        "Bash(rm -rf /*)"
        "Bash(rm -rf /)"
        "Bash(sudo rm -:*)"
        "Bash(chmod 777 /*)"
        "Bash(chmod -R 777 /*)"
        "Bash(dd if=:*)"
        "Bash(mkfs.:*)"
        "Bash(fdisk -:*)"
        "Bash(format -:*)"
        "Bash(shutdown -:*)"
        "Bash(reboot -:*)"
        "Bash(halt -:*)"
        "Bash(poweroff -:*)"
        "Bash(killall -:*)"
        "Bash(pkill -:*)"
        "Bash(nc -l -:*)"
        "Bash(ncat -l -:*)"
        "Bash(netcat -l -:*)"
        "Bash(rm -rf ~:*)"
        "Bash(rm -rf $HOME:*)"
        "Bash(rm -rf ~/.ssh*)"
        "Bash(rm -rf ~/.config*)"
      ];
    };

    hooks = {
      WorktreeCreate = [
        {
          hooks = [
            {
              type = "command";
              command = "${claudeDotfilesDir}/hooks/worktree.zsh";
            }
          ];
        }
      ];

      WorktreeRemove = [
        {
          hooks = [
            {
              type = "command";
              command = "${claudeDotfilesDir}/hooks/worktree.zsh";
            }
          ];
        }
      ];
    };
  };

  darwinSettings = lib.optionalAttrs pkgs.stdenv.isDarwin {
    hooks = {
      PreToolUse = [
        {
          matcher = "Read";
          hooks = [
            {
              type = "command";
              command = "${claudeDotfilesDir}/hooks/obsidian-backlinks.zsh";
            }
          ];
        }
      ];

      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = "${claudeDotfilesDir}/hooks/notify.zsh";
            }
          ];
        }
      ];

      PermissionRequest = [
        {
          hooks = [
            {
              type = "command";
              command = "${claudeDotfilesDir}/hooks/notify.zsh";
            }
          ];
        }
      ];

      Notification = [
        {
          hooks = [
            {
              type = "command";
              command = "CMUX_BIN=\"\"; if command -v cmux >/dev/null 2>&1; then CMUX_BIN=cmux; elif [ -x /Applications/cmux.app/Contents/Resources/bin/cmux ]; then CMUX_BIN=/Applications/cmux.app/Contents/Resources/bin/cmux; fi; if [ -n \"$CMUX_TAB_ID\" ] && [ -n \"$CMUX_BIN\" ]; then \"$CMUX_BIN\" set-app-focus active; \"$CMUX_BIN\" select-workspace --workspace \"$CMUX_TAB_ID\" && ${jq} -r '.message' | xargs -I {} \"$CMUX_BIN\" notify --title \"Claude Code\" --body \"{}\" --tab \"$CMUX_TAB_ID\"; else ${jq} -r '.message' | xargs -I {} ${terminal-notifier} -message \"{}\" -title \"Claude Code\" -group \"$(pwd):hook\"; fi";
            }
          ];
        }
      ];
    };
  };

  mergeSettings =
    base: override:
    let
      baseHooks = base.hooks or { };
      overrideHooks = override.hooks or { };

      allHookKeys = lib.unique (lib.attrNames baseHooks ++ lib.attrNames overrideHooks);

      mergedHooks = lib.genAttrs allHookKeys (
        key: (baseHooks.${key} or [ ]) ++ (overrideHooks.${key} or [ ])
      );
    in
    base
    // override
    // {
      hooks = mergedHooks;
    };

  settings = mergeSettings baseSettings darwinSettings;
in
{
  options.my.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code";

    telemetry = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Claude Code OTLP telemetry.";
      };

      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "http://B450M-Pro4.tail29d068.ts.net:4318";
        description = "OTLP HTTP endpoint for Claude Code telemetry.";
      };

      logUserPrompts = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Forward raw user prompts in Claude Code telemetry.";
      };

      resourceAttributes = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          "deployment.environment" = "home";
          role = "developer";
          team = "personal";
        };
        description = "OTel resource attributes attached to Claude Code telemetry.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs.llm-agents.claude-code;
      configDir = claudeConfigDir;
      enableMcpIntegration = true;
      inherit settings;
    };

    home.packages = with pkgs.llm-agents; [
      apm
      ccusage
    ];

    xdg.configFile = {
      "claude/hooks".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/hooks";

      "claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/CLAUDE.md";

      "claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/commands";

      "claude/agents".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/agents";

      "claude/output-styles".source =
        config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/output-styles";

      "claude/rules".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/rules";
    };
  };
}
