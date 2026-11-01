{
  config,
  lib,
  pkgs,
  ...
}:
{
  home = {
    username = "box";
    # bootstrap validates this against the actual account before changing anything.
    homeDirectory = "/home/box";
    packages = [ pkgs.zsh ];
    sessionPath = [ "${config.home.homeDirectory}/.nix-profile/bin" ];
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      build-users-group = "";
    };
  };

  targets.genericLinux.enable = true;
  systemd.user.enable = false;
  my = {
    profiles = {
      base.enable = true;
      development.enable = true;
    };
    # The hosted VM has no desktop audio session or access to the home tailnet.
    programs = {
      pi.acp.enable = true;
      codex = {
        acp.enable = true;
        desktopIntegration = false;
        telemetry = {
          enable = false;
          environment = "grok-bot";
        };
      };
      claude-code = {
        acp.enable = true;
        telemetry.enable = false;
      };
    };
  };
  programs = {
    claude-code.settings.env.ANTHROPIC_BASE_URL = lib.mkForce "https://api.anthropic.com";
    atuin.settings.auto_sync = lib.mkForce false;
    # Keep the provider's login shell; expose the profile to new Bash sessions.
    bash.enable = true;
  };
  mcp-servers.settings.servers = lib.mkForce { };
  xdg.configFile."opencode/opencode.json".text = lib.mkForce (
    builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      autoupdate = false;
    }
  );

}
