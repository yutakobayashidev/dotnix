_:

{
  flake.modules.homeManager.herdr-app =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.herdr-app.enable = lib.mkEnableOption "Herdr desktop app";

      config = lib.mkIf config.my.programs.herdr-app.enable {
        home.packages = [ pkgs.herdr-app ];
      };
    };
}
