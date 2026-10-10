_:

{
  flake.modules.homeManager.nlobby-cli =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
      options.my.programs.nlobby-cli.enable = lib.mkEnableOption "nlobby-cli";

      config = lib.mkIf config.my.programs.nlobby-cli.enable {
        home.packages = [ pkgs.nlobby-cli ];
      };
    };
}
