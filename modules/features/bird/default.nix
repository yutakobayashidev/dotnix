_:

{
  flake.modules.homeManager."bird" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.bird;
    in
    {
      options.my.programs.bird.enable = lib.mkEnableOption "Bird";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.bird ];

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
