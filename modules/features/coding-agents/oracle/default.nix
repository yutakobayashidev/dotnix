_:

{
  flake.modules.homeManager."oracle" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.oracle;
    in
    {
      options.my.programs.oracle.enable = lib.mkEnableOption "Oracle";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.oracle ];
      };
    };
}
