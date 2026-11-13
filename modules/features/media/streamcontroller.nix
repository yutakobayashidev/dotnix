{ inputs, ... }:
{
  flake.modules.nixos.streamcontroller =
    { config, lib, ... }:
    {
      imports = [ inputs.streamcontroller.nixosModules.default ];

      options.my.programs.streamcontroller.enable = lib.mkEnableOption "StreamController";

      config = lib.mkIf config.my.programs.streamcontroller.enable {
        nixpkgs.overlays = [ inputs.streamcontroller.overlays.default ];
        programs.streamcontroller = {
          enable = true;
          autostart = true;
        };
        home-manager.sharedModules = [
          { my.programs.streamcontroller.enable = lib.mkDefault true; }
        ];
      };
    };

  flake.modules.homeManager.streamcontroller =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.streamcontroller.homeModules.default ];

      options.my.programs.streamcontroller.enable =
        lib.mkEnableOption "StreamController page configuration";

      config = lib.mkIf (config.my.programs.streamcontroller.enable && pkgs.stdenv.isLinux) {
        programs.streamcontroller.enable = true;
      };
    };
}
