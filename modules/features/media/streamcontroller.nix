{ inputs, ... }:
{
  flake.modules.nixos.streamcontroller =
    {
      config,
      lib,
      options,
      ...
    }:
    {
      imports = [ inputs.streamcontroller.nixosModules.default ];

      options.my.programs.streamcontroller.enable = lib.mkEnableOption "StreamController";

      config = lib.mkIf config.my.programs.streamcontroller.enable (
        lib.mkMerge [
          {
            nixpkgs.overlays = [ inputs.streamcontroller.overlays.default ];
            programs.streamcontroller = {
              enable = true;
              autostart = true;
            };
          }
          (lib.optionalAttrs (lib.hasAttrByPath [ "home-manager" "sharedModules" ] options) {
            # WSL does not import Home Manager; even a disabled mkIf must use known options.
            home-manager.sharedModules = [
              { my.programs.streamcontroller.enable = lib.mkDefault true; }
            ];
          })
        ]
      );
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

      config = lib.mkIf (config.my.programs.streamcontroller.enable && pkgs.stdenv.hostPlatform.isLinux) {
        programs.streamcontroller.enable = true;
      };
    };
}
