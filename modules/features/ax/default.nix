_:

{
  flake.modules.homeManager."ax" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.ax;
    in
    {
      options.my.programs.ax.enable = lib.mkEnableOption "ax CLI";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.ax ];

        programs.agent-skills.skills.explicit.trend-daily = {
          from = "local";
          path = "trend-daily";
          packages = [ pkgs.ax ];
        };
      };
    };
}
