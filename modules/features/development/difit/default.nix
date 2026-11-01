_:

{
  flake.modules.homeManager."difit" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.my.programs.difit;
      registrySources = import ../../../../lib/skill-sources.nix { inherit inputs; };
    in
    {
      options.my.programs.difit.enable = lib.mkEnableOption "difit";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.difit ];

        programs.agent-skills = {
          sources.difit = registrySources.difit;
          skills.enableAll = [ "difit" ];
        };
      };
    };
}
