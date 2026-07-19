{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      agentLib = inputs.agent-skills.lib.agent-skills;

      sources = {
        hashicorp = {
          path = inputs.hashicorp-agent-skills;
        };
      };

      catalog = agentLib.discoverCatalog sources;
      allowlist = agentLib.allowlistFor {
        inherit catalog sources;
        enableAll = true;
      };
      selection = agentLib.selectSkills {
        inherit catalog allowlist sources;
        skills = { };
      };
      bundle = agentLib.mkBundle { inherit pkgs selection; };
      localTargets = builtins.mapAttrs (
        _: target:
        target
        // {
          enable = true;
        }
      ) agentLib.defaultLocalTargets;
    in
    {
      _module.args.agentSkillsShellHook = agentLib.mkShellHook {
        inherit pkgs bundle;
        targets = localTargets;
      };
    };
}
