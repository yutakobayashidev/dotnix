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
              anthropic
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

              docx = {
                from = "anthropic";
                path = "docx";
              };
              pdf = {
                from = "anthropic";
                path = "pdf";
              };
              pptx = {
                from = "anthropic";
                path = "pptx";
              };
              xlsx = {
                from = "anthropic";
                path = "xlsx";
              };

              frontend-design = {
                from = "anthropic";
                path = "frontend-design";
              };
              skill-creator = {
                from = "anthropic";
                path = "skill-creator";
              };
              webapp-testing = {
                from = "anthropic";
                path = "webapp-testing";
              };
              create-cli = {
                from = "agent-scripts";
                path = "create-cli";
              };

              skill-cleaner = {
                from = "agent-scripts";
                path = "skill-cleaner";
              };

              twitter-api-relay = {
                from = "twitter-api-relay";
                path = "twitter-api-relay";
              };

              prompt-review = {
                from = "prompt-review";
                path = "prompt-review";
              };

              grilling = {
                from = "mattpocock";
                path = "productivity/grilling";
              };

              loop-me = {
                from = "mattpocock";
                path = "in-progress/loop-me";
              };

              retro = {
                from = "mattpocock";
                path = "engineering/retro";
              };

              writing-for-agents = {
                from = "mattpocock";
                path = "productivity/writing-for-agents";
              };
            };

          targets = builtins.mapAttrs (_: target: target // { enable = true; }) agentLib.defaultTargets;
        };
      };
    };
}
