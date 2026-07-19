{ inputs, ... }:

{
  flake.homeManagerModules.vicinae =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.vicinae.enable = lib.mkEnableOption "Vicinae application launcher";

      config = lib.mkIf config.my.programs.vicinae.enable {
        programs.vicinae = {
          enable = true;
          useLayerShell = true;
          systemd = {
            enable = true;
            autoStart = true;
          };

          settings = {
            font.size = 11;
            close_on_focus_loss = true;
            consider_preedit = true;
            pop_to_root_on_close = true;
            favicon_service = "twenty";
            search_files_in_root = true;
            window = {
              csd = true;
              opacity = 0.95;
              rounding = 10;
            };
          };

          extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
            nix
            niri
            zoxide-recent-directories
            ssh
            port-killer
          ];
        };
      };
    };
}
