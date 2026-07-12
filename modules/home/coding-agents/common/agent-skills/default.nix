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
  edcbToolsPackage = pkgs.edcb-tools;

  agentScriptsSrc = builtins.path {
    path = inputs.agent-scripts;
    name = "agent-scripts-no-symlinks";
    filter = _path: type: type != "symlink";
  };
  herdrSkillSrc = builtins.path {
    path = inputs.herdr-skill;
    name = "herdr-skill-no-symlinks";
    filter = _path: type: type != "symlink";
  };
in
{
  options.my.programs.agent-skills.enable = lib.mkEnableOption "agent skills";

  config = lib.mkIf cfg.enable {
    home.sessionVariables.TWITTER_RELAY_BASE_URL = "https://tw.home.yutakobayashi.com";

    programs.agent-skills = {
      enable = true;

      sources = {
        local = {
          path = inputs.skills;
          subdir = "skills";
        };
        anthropic = {
          path = inputs.anthropic-skills;
          subdir = "skills";
        };
        superpowers = {
          path = inputs.superpowers;
          subdir = "skills";
        };
        ast-grep = {
          path = inputs.ast-grep-skill;
          subdir = "ast-grep/skills";
        };
        obsidian = {
          path = inputs.obsidian-skills;
          subdir = "skills";
        };
        repiq = {
          path = inputs.repiq;
          subdir = "skills";
        };
        prompt-review = {
          path = inputs.prompt-review-skill;
          subdir = ".claude/skills";
        };
        difit = {
          path = inputs.difit-skills;
          subdir = "skills";
        };
        agent-browser = {
          path = inputs.agent-browser-skill;
          subdir = "skills";
        };
        agent-scripts = {
          path = agentScriptsSrc;
          subdir = "skills";
          idPrefix = "agent-scripts";
        };
        before-and-after = {
          path = inputs.before-and-after-skill;
          subdir = "skill";
        };
        mattpocock = {
          path = inputs.mattpocock-skills;
          subdir = "skills";
        };
        twitter-api-relay = {
          path = inputs.twitter-api-safe-relay-skills;
          subdir = "skills";
        };
        openclaw-discrawl = {
          path = inputs.openclaw;
          subdir = ".agents/skills/discrawl";
        };
        edcb-tools = {
          path = inputs.edcb-tools;
          subdir = ".agents/skills";
        };
        herdr.path = herdrSkillSrc;
      };

      skills.enableAll = [
        "local"
        "obsidian"
        "repiq"
        "difit"
        "superpowers"
      ];

      skills.explicit = {
        before-and-after =
          let
            bnaBin = lib.getExe pkgs.before-and-after;
          in
          {
            from = "before-and-after";
            path = ".";
            packages = [ pkgs.before-and-after ];
            rewriteCommands = false;
            transform =
              { original, ... }:
              builtins.replaceStrings
                [
                  "`which before-and-after || npm install -g @vercel/before-and-after`"
                  "npm install -g @vercel/before-and-after"
                  "npx @vercel/before-and-after"
                ]
                [
                  "`which before-and-after`"
                  "# (installed via Nix)"
                  bnaBin
                ]
                original;
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
        discrawl = {
          from = "openclaw-discrawl";
          path = ".";
        };
        edcb-tools = {
          from = "edcb-tools";
          path = "edcb-tools";
          packages = [ edcbToolsPackage ];
        };
        herdr = {
          from = "herdr";
          path = ".";
        };

        agent-browser =
          let
            agentBrowserBin = "${config.home.homeDirectory}/.agents/skills/agent-browser/agent-browser";
          in
          {
            from = "agent-browser";
            path = "agent-browser";
            packages = [ pkgs.llm-agents.agent-browser ];
            rewriteCommands = false;
            transform =
              { original, ... }:
              builtins.replaceStrings
                [
                  "Bash(agent-browser:*), Bash(npx agent-browser:*)"
                  "Install: `npm i -g agent-browser && agent-browser install`\n\n"
                  "agent-browser skills "
                  "`agent-browser`"
                ]
                [
                  "Bash(${agentBrowserBin}:*)"
                  ""
                  "${agentBrowserBin} skills "
                  "`${agentBrowserBin}`"
                ]
                original;
          };

        create-cli = {
          from = "agent-scripts";
          path = "create-cli";
        };

        skill-cleaner = {
          from = "agent-scripts";
          path = "skill-cleaner";
        };

        ast-grep =
          let
            astGrepBin = lib.getExe pkgs.ast-grep;
          in
          {
            from = "ast-grep";
            path = "ast-grep";
            packages = [ pkgs.ast-grep ];
            rewriteCommands = false;
            transform =
              { original, dependencies }:
              let
                patched =
                  builtins.replaceStrings
                    [ "| ast-grep " "ast-grep scan " "ast-grep run " ]
                    [ "| ${astGrepBin} " "${astGrepBin} scan " "${astGrepBin} run " ]
                    original;
              in
              ''
                ${patched}

                ${dependencies}
              '';
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
      };

      targets = builtins.mapAttrs (_: target: target // { enable = true; }) agentLib.defaultTargets;
    };
  };
}
