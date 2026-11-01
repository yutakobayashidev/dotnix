_:

{
  flake.modules.homeManager.flare-social =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.flare-social.enable = lib.mkEnableOption "Flare social client";

      config = lib.mkIf config.my.programs.flare-social.enable {
        home.packages = [ pkgs.flare-social ];
      };
    };
}
