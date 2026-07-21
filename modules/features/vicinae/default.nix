{ inputs, ... }:

{
  flake.modules.homeManager.vicinae =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      mkLinuxRayCastExtension =
        {
          name,
          rev,
          hash,
          apiVersion,
          cliHash,
        }:
        let
          raycastCli = pkgs.fetchurl {
            url = "https://cli.raycast.com/${apiVersion}/linux/ray";
            hash = cliHash;
            executable = true;
          };
        in
        inputs.vicinae-extensions.inputs.vicinae.lib.${system}.mkRayCastExtension {
          inherit name rev hash;
          buildPhase = "${raycastCli} build -e dist";
        };
      natureRemo = mkLinuxRayCastExtension {
        name = "nature-remo";
        rev = "a03e4c58dd53593042397b412413afda7117790e";
        hash = "sha256-vU8VUfhbATkoT0ba8j7CiPIn4XDenJsQjKW1VCs2LSM=";
        apiVersion = "1.40.0";
        cliHash = "sha256-0YKDMi2se9ghpAeBw43gQMouXusXJxYmKCDYgTpFR6A=";
      };
      searchMdn = mkLinuxRayCastExtension {
        name = "search-mdn";
        rev = "a03e4c58dd53593042397b412413afda7117790e";
        hash = "sha256-FNRbJuyBqM+k6SNkEzdMz9vfNsNgiq1kdKRlzPDSMsg=";
        apiVersion = "1.76.1";
        cliHash = "sha256-HQvbqCgGzBxuu+BcbhGHUGYi2e5CkhYhu2i86mZwysw=";
      };
    in
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

          extensions = with inputs.vicinae-extensions.packages.${system}; [
            nix
            niri
            zoxide-recent-directories
            ssh
            port-killer
            natureRemo
            searchMdn
          ];
        };

        systemd.user.services.vicinae.Service.Environment = [
          "_JAVA_AWT_WM_NONREPARENTING=1"
        ];
      };
    };
}
