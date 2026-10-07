_:

{
  flake.modules.homeManager."similarity-ts" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.similarity-ts;
    in
    {
      options.my.programs.similarity-ts.enable = lib.mkEnableOption "similarity-ts";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.similarity-ts ];

        programs.agent-skills.skills.explicit.check-similarity = {
          from = "local";
          path = "check-similarity";
          packages = [ pkgs.similarity-ts ];
        };
      };
    };
}
