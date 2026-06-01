{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.my.programs.agent-skills;
in
{
  options.my.programs.agent-skills.enable = lib.mkEnableOption "agent skills";

  config = lib.mkIf cfg.enable {
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
        vercel = {
          path = inputs.vercel-skills;
          subdir = "skills";
        };
        nextlevelbuilder = {
          path = inputs.ui-ux-pro-max-skill;
          subdir = ".claude/skills";
        };
        ast-grep = {
          path = inputs.ast-grep-skill;
          subdir = "ast-grep/skills";
        };
        deno = {
          path = inputs.deno-skills;
          subdir = "skills";
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
        modern-web-guidance = {
          path = inputs.modern-web-guidance;
          subdir = "skills";
        };
        mattpocock = {
          path = inputs.mattpocock-skills;
          subdir = "skills";
        };
        twitter-api-replay = {
          path = inputs.twitter-api-safe-relay-skills;
          subdir = "skills";
        };
      };

      skills.enableAll = [
        "local"
        "cloudflare"
        "hashicorp"
        "deno"
        "aws"
        "obsidian"
        "repiq"
        "difit"
      ];

      skills.explicit = {
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

        find-skills = {
          from = "vercel";
          path = "find-skills";
        };

        ui-ux-pro-max = {
          from = "nextlevelbuilder";
          path = "ui-ux-pro-max";
        };

        agent-browser =
          let
            agentBrowserBin = lib.getExe pkgs.llm-agents.agent-browser;
          in
          {
            from = "agent-browser";
            path = "agent-browser";
            packages = [ pkgs.llm-agents.agent-browser ];
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

        ast-grep =
          let
            astGrepBin = lib.getExe pkgs.ast-grep;
          in
          {
            from = "ast-grep";
            path = "ast-grep";
            packages = [ pkgs.ast-grep ];
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

        twitter-api-replay =
          let
            dollar = "$";
          in
          {
            from = "twitter-api-replay";
            path = "twitter-api-replay";
            transform =
              { original, ... }:
              builtins.replaceStrings
                [
                  "$TWITTER_REPLAY_BASE_URL"
                  "${dollar}{TWITTER_REPLAY_BASE_URL%/}"
                ]
                [
                  "https://tw.home.yutakobayashi.com"
                  "https://tw.home.yutakobayashi.com"
                ]
                original;
          };

        prompt-review = {
          from = "prompt-review";
          path = "prompt-review";
        };

        modern-web-guidance = {
          from = "modern-web-guidance";
          path = "modern-web-guidance";
        };

        grill-me = {
          from = "mattpocock";
          path = "productivity/grill-me";
        };
      };

      targets = {
        agents.enable = true;
        claude.enable = true;
        codex.enable = true;
      };
    };
  };
}
