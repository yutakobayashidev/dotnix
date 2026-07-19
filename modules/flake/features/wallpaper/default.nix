_:

{
  flake.homeManagerModules.wallpaper =
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

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.swaybg ];

        programs.niri.settings.spawn-at-startup = [
          {
            command = [
              (lib.getExe pkgs.swaybg)
              "-i"
              (toString cfg.imagePath)
              "-m"
              "fill"
            ];
          }
        ];
      };
    };
}
