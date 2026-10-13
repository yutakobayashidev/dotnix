_:

{
  flake.modules.homeManager.claude-desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.claude-desktop;
    in
    {
      options.my.programs.claude-desktop.enable = lib.mkEnableOption "Claude Desktop";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.claude-desktop ];
      };
    };
}
