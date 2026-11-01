_:

{
  flake.modules.homeManager."similarity-ts" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      registrySources = import ../../../../lib/skill-sources.nix { inherit inputs; };
      cfg = config.my.programs.similarity-ts;
    in
    {
      options.my.programs.similarity-ts.enable = lib.mkEnableOption "similarity-ts";

      config = lib.mkIf cfg.enable {
        programs.agent-skills.sources.local = registrySources.local;
        home.packages = [ pkgs.similarity-ts ];

        programs.agent-skills.skills.explicit.check-similarity = {
          from = "local";
          path = "check-similarity";
          packages = [ pkgs.similarity-ts ];
        };
      };
    };
}
