_:

{
  flake.modules.homeManager."omp" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.omp;
    in
    {
      options.my.programs.omp.enable = lib.mkEnableOption "Oh My Pi";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.omp ];
      };
    };
}
