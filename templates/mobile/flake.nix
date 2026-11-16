{
  description = "Android development and APK analysis for Linux coding agents";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.agent-skills = {
    url = "github:Kyure-A/agent-skills-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, agent-skills, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };
      settings = import ./nix/settings.nix;
      agentLib = agent-skills.lib.agent-skills;
      skills = import ./nix/skills.nix { inherit pkgs agentLib; };
      mkMobileShell = import ./nix/shell.nix {
        inherit pkgs settings;
        skillsShellHook = skills.shellHook;
      };
    in
    {
      devShells.${system} = {
        default = mkMobileShell { };
        analysis = mkMobileShell { analysis = true; };
        full = mkMobileShell {
          analysis = true;
          nativeAnalysis = true;
        };
      };
      formatter.${system} = pkgs.nixfmt;
      packages.${system}.skills = skills.bundle;
      apps.${system}.skills-sources-lock = {
        type = "app";
        meta.description = "Update the pinned official Android skills";
        program = "${agentLib.mkSourceLockProgram { inherit pkgs; }}/bin/skills-sources-lock";
      };
      checks.${system} = {
        skills = pkgs.runCommand "mobile-skills-check" { } ''
          mkdir project
          cd project
          ${skills.shellHook}
          for target in .agents .codex .claude .opencode; do
            test -f "$target/skills/android-cli/SKILL.md"
            test -f "$target/skills/.agent-skills-managed.json"
          done
          touch "$out"
        '';
        scripts =
          pkgs.runCommand "mobile-script-checks"
            {
              nativeBuildInputs = [
                pkgs.shellcheck
                pkgs.python3
                pkgs.bash
              ];
            }
            ''
              shellcheck ${./scripts/mobile.sh}
              python3 ${./scripts/test_mobile.py} ${./scripts/mobile.sh}
              touch "$out"
            '';
      };
    };
}
