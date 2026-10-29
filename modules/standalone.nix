{
  inputs,
  lib,
  withSystem,
  ...
}:
{
  flake.homeConfigurations.grok-bot = withSystem "x86_64-linux" (
    { pkgs, ... }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgs.extend (
        _final: prev:
        let
          inherit (prev.stdenv.hostPlatform) system;
        in
        {
          ax = inputs.ax.packages.${system}.default;
          edcb-tools = inputs.edcb-tools.packages.${system}.edcb-tools;
          gogcli = inputs.nix-openclaw-tools.packages.${system}.gogcli;
          gh-graph = inputs.gh-graph.packages.${system}.default;
          gh-nippou = inputs.gh-nippou.packages.${system}.default;
          repiq = inputs.repiq.packages.${system}.default;
        }
      );
      extraSpecialArgs = {
        # No NixOS/nix-darwin system configuration exists in this VM.
        osConfig = { };
        inherit inputs;
        helpers = import ../lib/helpers { inherit lib; };
        dotfilesDir = inputs.self.outPath;
      };
      modules = [
        inputs.agent-skills.homeManagerModules.default
        inputs.nix-index-database.homeModules.nix-index
        inputs.sops-nix.homeManagerModules.sops
        ../homes/common.nix
        ../homes/standalone/grok-bot
      ]
      ++ builtins.attrValues inputs.self.modules.homeManager;
    }
  );
}
