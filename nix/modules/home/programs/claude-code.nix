{ lib, config, pkgs, dotfilesDir, ... }:

let
  claudeConfigDir = "${config.xdg.configHome}/claude";
  claudeDotfilesDir = "${dotfilesDir}/claude";
  jq = lib.getExe pkgs.jq;
in
{
  home.sessionVariables = {
    CLAUDE_CONFIG_DIR = claudeConfigDir;
  };

  xdg.configFile = {
    "claude/settings.json".text = builtins.toJSON {
      "$schema" = "https://json.schemastore.org/claude-code-settings.json";
      env = {
        IS_DEMO = "1";
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
      enabledPlugins = {
        "gopls-lsp@claude-plugins-official" = true;
      };
      language = "Japanese";
      skipDangerousModePermissionPrompt = true;
      statusline = {
        type = "command";
        command = "ccusage statusline";
        padding = 0;
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
    "claude/hooks".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/hooks";
    "claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/CLAUDE.md";
    "claude/commands".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/commands";
    "claude/agents".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/agents";
    "claude/output-styles".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/output-styles";
    "claude/rules".source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/rules";
  };

  home.activation.validateClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_FILE="${claudeConfigDir}/settings.json"
    SCHEMA_URL=$(${jq} -r '.["$schema"]' "$SETTINGS_FILE")

    echo "Validating Claude Code settings.json..."
    if ${pkgs.check-jsonschema}/bin/check-jsonschema --schemafile "$SCHEMA_URL" "$SETTINGS_FILE" 2>&1; then
      echo "Claude Code settings.json validation passed"
    else
      echo "Claude Code settings.json validation failed" >&2
      exit 1
    fi
  '';
}
