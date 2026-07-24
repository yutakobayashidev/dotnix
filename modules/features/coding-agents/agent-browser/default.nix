_:

{
  flake.modules.homeManager."agent-browser" =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.my.programs.agent-browser;
      agentBrowserBin = "${config.home.homeDirectory}/.agents/skills/agent-browser/agent-browser";
    in
    {
      options.my.programs.agent-browser.enable = lib.mkEnableOption "agent-browser";

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.llm-agents.agent-browser ];

        programs.agent-skills = {
          sources.agent-browser = {
            path = inputs.agent-browser-skill;
            subdir = "skills";
          };

          skills.explicit.agent-browser = {
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
        };
      };
    };
}
