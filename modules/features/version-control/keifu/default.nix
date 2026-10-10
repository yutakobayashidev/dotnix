_:

{
  flake.modules.homeManager.keifu =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
      options.my.programs.keifu.enable = lib.mkEnableOption "keifu";

      config = lib.mkIf config.my.programs.keifu.enable {
        home.packages = lib.optionals pkgs.stdenv.isLinux [
          pkgs.keifu
        ];
      };
    };
}
