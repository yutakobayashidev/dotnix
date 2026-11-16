_:

{
  flake.modules.homeManager.lazydsh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.lazydsh.enable = lib.mkEnableOption "lazydsh";

      config = lib.mkIf config.my.programs.lazydsh.enable {
        home.packages = [ pkgs.lazydsh ];
      };
    };
}
