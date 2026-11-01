_:

{
  flake.modules.homeManager."bird" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      registrySources = import ../../../../lib/skill-sources.nix { inherit inputs; };
      cfg = config.my.programs.bird;
    in
    {
      options.my.programs.bird.enable = lib.mkEnableOption "Bird";

      config = lib.mkIf cfg.enable {
        programs.agent-skills.sources.local = registrySources.local;
        home.packages = [ pkgs.bird ];
        home.sessionVariables.TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";

        programs.agent-skills.skills.explicit = {
          bird = {
            from = "local";
            path = "bird";
            packages = [ pkgs.bird ];
          };
          bird-deep-research = {
            from = "local";
            path = "bird-deep-research";
            packages = [
              pkgs.bird
              pkgs.nodejs
            ];
          };
        };
      };
    };
}
