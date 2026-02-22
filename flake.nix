{
  description = "yuta's NixOS & macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ghostty.url = "github:ghostty-org/ghostty";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    gh-nippou = {
      url = "github:ryoppippi/gh-nippou";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-hazkey = {
      url = "github:aster-void/nix-hazkey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    version-lsp = {
      url = "github:skanehira/version-lsp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
    vercel-skills = {
      url = "github:vercel-labs/skills";
      flake = false;
    };
    ui-ux-pro-max-skill = {
      url = "github:nextlevelbuilder/ui-ux-pro-max-skill";
      flake = false;
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    onepassword-shell-plugins.url = "github:1Password/shell-plugins";
    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
    nix-filter.url = "github:numtide/nix-filter";
  };

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  outputs =
    {
      self,
      nixpkgs,
      ghostty,
      home-manager,
      niri,
      llm-agents,
      gh-nippou,
      nix-hazkey,
      version-lsp,
      agent-skills,
      anthropic-skills,
      vercel-skills,
      ui-ux-pro-max-skill,
      nix-darwin,
      onepassword-shell-plugins,
      moonbit-overlay,
      nix-filter,
      ...
    }:
    let
      # Helper functions for home-manager
      helpers = import ./nix/modules/lib/helpers { lib = nixpkgs.lib; };

      # Dotfiles directory path helper
      mkDotfilesDir = homeDir: "${homeDir}/ghq/github.com/yutakobayashidev/dotnix";

      # Local agent skills (filtered from this repo)
      local-skills = nix-filter.lib {
        root = self;
        include = [ "agents/skills" ];
      };

      # Overlay for external flake packages (parameterized by system)
      mkExternalOverlay = system: final: prev: {
        claude-code = llm-agents.packages.${system}.claude-code;
        ccusage = llm-agents.packages.${system}.ccusage;
        codex = llm-agents.packages.${system}.codex;
        opencode = llm-agents.packages.${system}.opencode;
        vibe-kanban = llm-agents.packages.${system}.vibe-kanban;
        version-lsp = version-lsp.packages.${system}.default.overrideAttrs (oldAttrs: {
          doCheck = false;
        });
        gh-nippou = gh-nippou.packages.${system}.default;
      } // (if builtins.match ".*-linux" system != null then {
        ghostty = ghostty.packages.${system}.default;
      } else {});

      # Custom package overlays
      customOverlay = import ./nix/overlays;

      # mkSystem helper function (NixOS)
      mkSystem =
        {
          host,
          system,
          profile,
          extraModules ? [ ],
        }:
        let
          dotfilesDir = mkDotfilesDir "/home/yuta";
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit helpers dotfilesDir home-manager niri local-skills anthropic-skills vercel-skills ui-ux-pro-max-skill agent-skills;
          };
          modules = [
            ./nix/modules/core
            ./nix/hosts/${host}
            ./nix/profiles/${profile}.nix
            {
              nixpkgs.overlays = [ (mkExternalOverlay system) moonbit-overlay.overlays.default customOverlay ];
              nixpkgs.config.allowUnfreePredicate =
                pkg: builtins.elem (nixpkgs.lib.getName pkg) [
                  "claude-code"
                  "android-studio"
                  "vscode"
                  "google-chrome"
                  "discord"
                  "slack"
                  "obsidian"
                  "1password"
                  "insomnia"
                  "spotify"
                ];
            }
            nix-hazkey.nixosModules.hazkey
          ] ++ extraModules;
        };

      # mkDarwin helper function (macOS)
      mkDarwin =
        {
          host,
          system,
          extraModules ? [ ],
        }:
        let
          dotfilesDir = mkDotfilesDir "/Users/yuta";
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit helpers dotfilesDir home-manager local-skills anthropic-skills vercel-skills ui-ux-pro-max-skill agent-skills onepassword-shell-plugins;
          };
          modules = [
            ./nix/modules/darwin
            ./nix/hosts/${host}
            ./nix/profiles/darwin.nix
            {
              nixpkgs.overlays = [ (mkExternalOverlay system) moonbit-overlay.overlays.default customOverlay ];
              nixpkgs.config.allowUnfreePredicate =
                pkg: builtins.elem (nixpkgs.lib.getName pkg) [
                  "claude-code"
                  "vscode"
                  "discord"
                  "slack"
                  "obsidian"
                  "1password"
                  "spotify"
                ];
            }
          ] ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        nixos = mkSystem {
          host = "nixos";
          system = "x86_64-linux";
          profile = "gui";
          extraModules = [ ];
        };
      };

      darwinConfigurations = {
        darwin = mkDarwin {
          host = "darwin";
          system = "aarch64-darwin";
        };
      };
    };
}
