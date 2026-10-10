_:

{
  flake.modules.homeManager.wallpaper =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.wallpaper;
    in
    {
      options.services.wallpaper = {
        enable = lib.mkEnableOption "desktop wallpaper";
        imagePath = lib.mkOption {
          type = lib.types.path;
          default = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
          description = "Path to the wallpaper image";
        };
      };

      config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
        programs.noctalia.settings.wallpaper = {
          enabled = true;
          default.path = toString cfg.imagePath;
        };
      };
    };
}
