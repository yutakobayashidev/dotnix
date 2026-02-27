{
  lib,
  config,
  pkgs,
  inputs,
  dotfilesDir,
  ...
}:

let
  claudeConfigDir = "${config.xdg.configHome}/claude";
  claudeDotfilesDir = "${dotfilesDir}/claude";
  inherit (config.home) homeDirectory;
  jq = lib.getExe pkgs.jq;
  rtk = lib.getExe pkgs.rtk;
  rtkHookPath = "${homeDirectory}/.claude/hooks/rtk-rewrite.sh";
  terminal-notifier =
    if pkgs.stdenv.isDarwin then lib.getExe' pkgs.terminal-notifier "terminal-notifier" else "";

  mcpServers =
    (inputs.mcp-servers-nix.lib.evalModule pkgs {
      programs = {
        context7.enable = true;
      };
    }).config.settings.servers
    // {
      deepwiki = {
        type = "http";
        url = "https://mcp.deepwiki.com/mcp";
      };
    };
in
{
  home.sessionVariables = {
    CLAUDE_CONFIG_DIR = claudeConfigDir;
  };

  xdg.configFile = {
    "claude/settings.json".text = builtins.toJSON {
      "$schema" = "https://json.schemastore.org/claude-code-settings.json";
      env = {
        BASH_DEFAULT_TIMEOUT_MS = "300000";
        BASH_MAX_TIMEOUT_MS = "1200000";
        CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR = "1";
        MAX_MCP_OUTPUT_TOKENS = "50000";
        MCP_TOOL_TIMEOUT = "120000";
        CLAUDE_CODE_MAX_OUTPUT_TOKENS = "32000";
        CLAUDE_CODE_AUTO_CONNECT_IDE = "0";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
        CLAUDE_CODE_ENABLE_TELEMETRY = "0";
        CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL = "1";
        CLAUDE_CODE_IDE_SKIP_VALID_CHECK = "1";
        DISABLE_AUTOUPDATER = "1";
        DISABLE_ERROR_REPORTING = "1";
        DISABLE_INTERLEAVED_THINKING = "1";
        DISABLE_MICROCOMPACT = "1";
        DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1";
        DISABLE_TELEMETRY = "1";
        ENABLE_EXPERIMENTAL_MCP_CLI = "false";
        ENABLE_TOOL_SEARCH = "true";
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        IS_DEMO = "1";
      };
      enabledPlugins = {
        "gopls-lsp@claude-plugins-official" = true;
      };
      cleanupPeriodDays = 876000;
      language = "Japanese";
      skipDangerousModePermissionPrompt = true;
      enableAllProjectMcpServers = true;
      inherit mcpServers;
      statusline = {
        type = "command";
        command = "ccusage statusline";
        padding = 0;
      };
      permissions = {
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
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = rtkHookPath;
                timeout = 10;
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
        Notification = lib.optionals pkgs.stdenv.isDarwin [
          {
            hooks = [
              {
                type = "command";
                command = "${jq} -r '.message' | xargs -I {} ${terminal-notifier} -message \"{}\" -title \"Claude Code\" -group \"$(pwd):hook\" -activate com.mitchellh.ghostty";
              }
            ];
          }
        ];
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
    "claude/hooks".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/hooks";
    "claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/CLAUDE.md";
    "claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/commands";
    "claude/agents".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/agents";
    "claude/output-styles".source =
      config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/output-styles";
    "claude/rules".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/rules";
  };

  home.activation.setupRtk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "Setting up rtk hook..."
    ${rtk} init -g --hook-only --no-patch 2>/dev/null || true
  '';

  home.activation.validateClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_FILE="${claudeConfigDir}/settings.json"
    SCHEMA_URL=$(${jq} -r '.["$schema"]' "$SETTINGS_FILE")

    echo "Validating Claude Code settings.json..."
    if ${pkgs.check-jsonschema}/bin/check-jsonschema --schemafile "$SCHEMA_URL" "$SETTINGS_FILE" 2>&1; then
      echo "Claude Code settings.json validation passed"
    else
      echo "Claude Code settings.json validation warning: schema validation failed (schemastore may be outdated)" >&2
    fi
  '';
}
