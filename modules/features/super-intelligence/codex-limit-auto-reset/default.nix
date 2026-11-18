{ inputs, ... }:

{
  flake.modules.homeManager.codex-limit-auto-reset = {
    imports = [ inputs.codex-limit-auto-reset.homeManagerModules.default ];
  };
}
