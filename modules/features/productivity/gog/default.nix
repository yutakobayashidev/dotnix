_:

{
  flake.modules.homeManager."gog" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.gog;
    in
    {
      options.my.programs.gog.enable = lib.mkEnableOption "gog CLI";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.gogcli ];

        programs.agent-skills.skills.explicit = {
          action-plan-daily = {
            from = "local";
            path = "action-plan-daily";
            packages = [ pkgs.gogcli ];
          };
          audit-email-noise = {
            from = "local";
            path = "audit-email-noise";
            packages = [ pkgs.gogcli ];
          };
        };
      };
    };
}
