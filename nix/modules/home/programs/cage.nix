# cage - ファイルシステムwrite制限サンドボックス
# macOS: sandbox-exec, Linux: Landlock LSM
{ lib, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;

  presetsConfig = {
    presets = {
      base = {
        allow = [
          "."
          "$XDG_CACHE_HOME"
          "$XDG_DATA_HOME"
        ]
        ++ lib.optionals isDarwin [
          "/private/tmp"
          "/var/folders"
          "$HOME/Library/Caches"
        ]
        ++ lib.optionals (!isDarwin) [
          "/tmp"
        ];
      };
      npm = {
        allow = [
          "$HOME/.npm"
          "$HOME/.npmrc"
          "$HOME/.pnpm-store"
        ];
      };
      "git-enabled" = {
        "allow-git" = true;
      }
      // lib.optionalAttrs isDarwin {
        "allow-keychain" = true;
      };
      "claude-code" = {
        allow = [
          "$CLAUDE_CONFIG_DIR"
          "$HOME/.claude"
          "$HOME/.claude.json"
          "$HOME/.claude.json.backup"
          "$HOME/.claude.json.lock"
          "$HOME/.claude.lock"
          "$HOME/.codex"
        ];
      };
    };
    "auto-presets" = [
      {
        command = "claude";
        presets = [
          "base"
          "git-enabled"
          "npm"
          "claude-code"
        ];
      }
      {
        command = "codex";
        presets = [
          "base"
          "git-enabled"
          "npm"
          "claude-code"
        ];
      }
    ];
  };

  configText = builtins.toJSON presetsConfig;

  # macOS: ~/Library/Application Support/cage/
  # Linux: ~/.config/cage/ (XDG_CONFIG_HOME)
  configFile =
    if isDarwin then
      { "Library/Application Support/cage/presets.yml".text = configText; }
    else
      { ".config/cage/presets.yml".text = configText; };
in
{
  home.packages = [ pkgs.cage ];
  home.file = configFile;
}
