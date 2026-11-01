_:

{
  flake.modules.homeManager.orca =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.orca;
    in
    {
      options.my.programs.orca.enable = lib.mkEnableOption "Orca";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.orca ];
      };
    };
}
