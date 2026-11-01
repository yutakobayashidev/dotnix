_:

{
  flake.modules.homeManager."agent-skills" =
    {
      config,
      pkgs,
      lib,
      inputs,
      ...
    }:
    let
      cfg = config.my.programs.agent-skills;
      agentLib = inputs.agent-skills.lib.agent-skills;
      registrySources = import ../../../../lib/skill-sources.nix { inherit inputs; };
      localCatalog = agentLib.discoverCatalog { inherit (registrySources) local; };
      # Explicit declarations merge with tool features' packages and transforms.
      # enableAll + explicit declarations would select the same skill twice.
      localSkills = lib.mapAttrs (_: skill: {
        from = lib.mkDefault "local";
        path = lib.mkDefault (if skill.relPath == "" then "." else skill.relPath);
      }) localCatalog;

      # The final path component is the deployed skill name.
      selectedSkillPaths = {
        agent-scripts = [
          "create-cli"
          "skill-cleaner"
        ];
        mattpocock = [
          "productivity/grilling"
          "in-progress/loop-me"
          "engineering/retro"
          "productivity/writing-for-agents"
        ];
        twitter-api-relay = [ "twitter-api-relay" ];
        prompt-review = [ "prompt-review" ];
      };
      selectedSkills = lib.concatMapAttrs (
        from: paths:
        lib.listToAttrs (
          map (
            path:
            lib.nameValuePair (builtins.baseNameOf path) {
              inherit from path;
            }
          ) paths
        )
      ) selectedSkillPaths;

      agentScriptsSrc = builtins.path {
        path = registrySources.agent-scripts.path;
        name = "agent-scripts-no-symlinks";
        filter = _path: type: type != "symlink";
      };
    in
    {
      options.my.programs.agent-skills.enable = lib.mkEnableOption "agent skills";

      config = lib.mkIf cfg.enable {
        programs.agent-skills = {
          enable = true;

          sources = {
            inherit (registrySources)
              local
              prompt-review
              mattpocock
              i-have-adhd
              twitter-api-relay
              japanese-tech-writing
              mizchi
              ;
            explain-diff = {
              # The Gist contains standalone Markdown files rather than skill directories.
              path = pkgs.writeTextDir "SKILL.md" (
                builtins.readFile "${registrySources.explain-diff.path}/explain-diff-html.md"
              );
            };
            agent-scripts = registrySources.agent-scripts // {
              path = agentScriptsSrc;
            };
          };

          skills.enableAll = [ "i-have-adhd" ];

          skills.explicit =
            localSkills
            // selectedSkills
            // (import ./mizchi.nix { inherit pkgs lib registrySources; })
            // {
              explain-diff-html = {
                from = "explain-diff";
                path = ".";
              };
              japanese-tech-writing = {
                from = "japanese-tech-writing";
                path = ".";
              };
            };

          targets = builtins.mapAttrs (_: target: target // { enable = true; }) agentLib.defaultTargets;
        };
      };
    };
}
