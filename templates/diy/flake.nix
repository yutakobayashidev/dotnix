{
  description = "Composable DIY environments for firmware, CAD, PCB design and 3D printing";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        brew-api.follows = "brew-api";
        nix-darwin.follows = "nix-darwin";
      };
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forSystems = inputs.nixpkgs.lib.genAttrs systems;
      environments = forSystems (
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          stable = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };
          agentLib = inputs.agent-skills.lib.agent-skills;
          skills = import ./nix/skills.nix { inherit pkgs agentLib; };
          mkShell = import ./nix/shell.nix {
            inherit pkgs stable skills;
            casks = if pkgs.stdenv.hostPlatform.isDarwin then inputs.brew-nix.packages.${system} else { };
          };
        in
        {
          shells = builtins.mapAttrs (_: features: mkShell { inherit features; }) (
            import ./nix/profiles.nix {
              inherit (pkgs) lib;
              inherit (pkgs.stdenv.hostPlatform) isDarwin;
            }
          );
          inherit skills pkgs;
        }
      );
    in
    {
      devShells = forSystems (system: environments.${system}.shells);
      formatter = forSystems (system: environments.${system}.pkgs.nixfmt);
      packages = forSystems (system: {
        skills = environments.${system}.skills.bundle;
      });
      checks = forSystems (
        system:
        let
          env = environments.${system};
        in
        {
          skills = env.pkgs.runCommand "diy-skills-check" { } ''
            mkdir project
            cd project
            ${env.skills.shellHook}
            for target in .agents .codex .claude .opencode; do
              test -f "$target/skills/diy-workflow/SKILL.md"
              test -f "$target/skills/.agent-skills-managed.json"
            done
            touch "$out"
          '';
        }
      );
    };
}
