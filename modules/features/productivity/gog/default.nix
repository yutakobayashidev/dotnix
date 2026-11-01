_:

{
  flake.modules.homeManager."gog" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      registrySources = import ../../../../lib/skill-sources.nix { inherit inputs; };
      cfg = config.my.programs.gog;
    in
    {
      options.my.programs.gog.enable = lib.mkEnableOption "gog CLI";

      config = lib.mkIf cfg.enable {
        programs.agent-skills.sources.local = registrySources.local;
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
