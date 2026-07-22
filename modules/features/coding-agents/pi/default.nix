_:

{
  flake.modules.homeManager."pi" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.pi;
    in
    {
      options.my.programs.pi.enable = lib.mkEnableOption "Pi";

      config = lib.mkIf cfg.enable {
        home.packages = [
          pkgs.llm-agents.pi
          pkgs.pi-acp
        ];
      };
    };
}
