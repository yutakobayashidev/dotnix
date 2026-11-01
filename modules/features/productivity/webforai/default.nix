_:

{
  flake.modules.homeManager."webforai" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.webforai;
    in
    {
      options.my.programs.webforai.enable = lib.mkEnableOption "webforai";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.webforai ];

        programs.agent-skills = {
          sources.webforai = {
            path = pkgs.webforai.src;
            subdir = "skills";
          };
          skills.explicit.webforai = import ../../../../lib/webforai-skill.nix { inherit lib pkgs; };
        };
      };
    };
}
