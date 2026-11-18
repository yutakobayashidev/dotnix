{ inputs, ... }:

{
  flake.modules.homeManager.codex-limit-auto-reset = { pkgs, ... }: {
    imports = [ inputs.codex-limit-auto-reset.homeManagerModules.default ];
    services.codex-limit-auto-reset.advisor.codexAuthPackage = pkgs.llm-agents.codex-auth;
  };
}
