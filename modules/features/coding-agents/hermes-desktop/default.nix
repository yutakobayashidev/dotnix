_:

{
  flake.modules.homeManager.hermes-desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.hermes-desktop;
    in
    {
      options.my.programs.hermes-desktop.enable = lib.mkEnableOption "Hermes Desktop";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.hermes-desktop ];
      };
    };
}
