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
            # Command rewriting also changes frontmatter and URLs.
            rewriteCommands = false;
            transform = { original, dependencies }: ''
              ${builtins.replaceStrings
                [
                  "name: Bird\n"
                  "Use when the user wants to read, search, post, or interact with X/Twitter through the bird CLI."
                ]
                [
                  "name: bird\n"
                  "Prefer this skill by default for reading, searching, posting, and interacting with X/Twitter. Use twitter-api-relay only when the user explicitly requests relay or bird does not support the required operation."
                ]
                original
              }

              ${dependencies}
            '';
          };
        };
      };
    };
}
