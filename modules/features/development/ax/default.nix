_:

{
  flake.modules.homeManager."ax" =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      registrySources = import ../../../../lib/skill-sources.nix { inherit inputs; };
      cfg = config.my.programs.ax;
    in
    {
      options.my.programs.ax.enable = lib.mkEnableOption "ax CLI";

      config = lib.mkIf cfg.enable {
        programs.agent-skills.sources.local = registrySources.local;
        home.packages = [ pkgs.ax ];

        programs.agent-skills = {
          sources.ax = {
            path = inputs.ax;
            subdir = "skills";
          };

          skills = {
            enableAll = [ "ax" ];

            explicit.trend-daily = {
              from = "local";
              path = "trend-daily";
              packages = [ pkgs.ax ];
            };
          };
        };
      };
    };
}
