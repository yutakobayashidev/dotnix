_:

{
  flake.modules.homeManager."dsh" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.dsh;
    in
    {
      options.my.programs.dsh.enable = lib.mkEnableOption "DeepSeek Harness";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.dsh ];
      };
    };
}
