_:

{
  flake.modules.homeManager.hunk =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.hunk;
      package = pkgs.llm-agents.hunk;
    in
    {
      options.my.programs.hunk.enable = lib.mkEnableOption "Hunk diff review and its agent skill";

      config = lib.mkIf cfg.enable {
        home.packages = [ package ];

        programs.agent-skills = {
          sources.hunk.path = "${package}/share/hunk/skills";
          skills.explicit.hunk-review = {
            from = "hunk";
            path = "hunk-review";
            rewriteCommands = false;
          };
        };
      };
    };
}
