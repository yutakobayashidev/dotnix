_:

{
  flake.modules.homeManager."amp" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.amp;
    in
    {
      options.my.programs.amp.enable = lib.mkEnableOption "Amp";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.amp ];
      };
    };
}
