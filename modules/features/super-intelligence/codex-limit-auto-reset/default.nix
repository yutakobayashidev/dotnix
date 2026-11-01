{ inputs, ... }:

{
  flake.modules.homeManager.codex-limit-auto-reset = {
    imports = [ inputs.nur-packages.homeModules.codex-limit-auto-reset ];
  };
}
