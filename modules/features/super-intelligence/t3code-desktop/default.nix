_:

{
  flake.modules.homeManager.t3code-desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.t3code-desktop;
    in
    {
      options.my.programs.t3code-desktop.enable = lib.mkEnableOption "T3 Code Desktop";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.t3code-desktop ];
      };
    };
}
