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
        home.packages = [ pkgs.swaybg ];

        systemd.user.services.swaybg = {
          Unit = {
            Description = "Wayland wallpaper";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${lib.getExe pkgs.swaybg} -i ${cfg.imagePath} -m fill";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
