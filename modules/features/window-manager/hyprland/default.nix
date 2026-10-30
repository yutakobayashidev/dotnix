_:

{
  flake.modules.nixos.hyprland =
    { config, lib, ... }:
    {
      options.my.programs.hyprland.enable = lib.mkEnableOption "Hyprland desktop session";

      config = lib.mkIf config.my.programs.hyprland.enable {
        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
        };
        home-manager.sharedModules = [
          { my.programs.hyprland.enable = lib.mkDefault true; }
        ];
      };
    };

  flake.modules.homeManager.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.hyprland.enable = lib.mkEnableOption "Hyprland configuration";

      config = lib.mkIf config.my.programs.hyprland.enable {
        wayland.windowManager.hyprland = {
          enable = true;
          # Use the compositor and portal installed by the NixOS module.
          package = null;
          portalPackage = null;
          systemd.enable = true;
          configType = "lua";
          settings = import ./settings.nix { inherit lib pkgs; };
        };
      };
    };
}
