{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      agentLib = inputs.agent-skills.lib.agent-skills;

      registrySources = import ../../lib/skill-sources.nix { inherit inputs; };
      sources = { inherit (registrySources) hashicorp; };

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
      apps.skills-sources-lock = {
        type = "app";
        program = "${agentLib.mkSourceLockProgram { inherit pkgs; }}/bin/skills-sources-lock";
      };

      _module.args.agentSkillsShellHook = agentLib.mkShellHook {
        inherit pkgs bundle;
        targets = localTargets;
      };
    };
}
