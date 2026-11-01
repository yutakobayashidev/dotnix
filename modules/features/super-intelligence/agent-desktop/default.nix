_:

{
  flake.modules.homeManager.agent-desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.programs.agent-desktop.enable = lib.mkEnableOption "Agent Desktop";

      config = lib.mkIf config.my.programs.agent-desktop.enable {
        home.packages = [ pkgs.agent-desktop ];
      };
    };
}
