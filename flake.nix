{
  description = "yuta's NixOS & macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    nix-steipete-tools.url = "github:openclaw/nix-steipete-tools";
    gh-nippou = {
      url = "github:ryoppippi/gh-nippou";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gh-graph = {
      url = "github:kawarimidoll/gh-graph";
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
    ast-grep-skill = {
      url = "github:ast-grep/claude-skill";
      flake = false;
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    onepassword-shell-plugins.url = "github:1Password/shell-plugins";
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs = {
        brew-api.follows = "brew-api";
        nix-darwin.follows = "nix-darwin";
        nixpkgs.follows = "nixpkgs";
      };
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
    nix-filter.url = "github:numtide/nix-filter";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://cache.numtide.com"
      "https://yuta.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "yuta.cachix.org-1:VGiC7m0kQjut7lp+RG/9pCRHFpzf11ELQrM2Nc2QCCk="
    ];
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      treefmt-nix,
      ghostty,
      home-manager,
      niri,
      llm-agents,
      nix-steipete-tools,
      gh-nippou,
      gh-graph,
      nix-hazkey,
      version-lsp,
      agent-skills,
      anthropic-skills,
      vercel-skills,
      ui-ux-pro-max-skill,
      ast-grep-skill,
      nix-darwin,
      onepassword-shell-plugins,
      brew-nix,
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
      mkExternalOverlay =
        system: final: prev:
        {
          claude-code = llm-agents.packages.${system}.claude-code;
          ccusage = llm-agents.packages.${system}.ccusage;
          codex = llm-agents.packages.${system}.codex;
          opencode = llm-agents.packages.${system}.opencode;
          vibe-kanban = llm-agents.packages.${system}.vibe-kanban;
          cursor-agent = llm-agents.packages.${system}.cursor-agent;
          gogcli = nix-steipete-tools.packages.${system}.gogcli;
          version-lsp = version-lsp.packages.${system}.default.overrideAttrs (oldAttrs: {
            doCheck = false;
          });
          gh-nippou = gh-nippou.packages.${system}.default;
          gh-graph = gh-graph.packages.${system}.default;
        }
        // (
          if builtins.match ".*-linux" system != null then
            {
              ghostty = ghostty.packages.${system}.default;
            }
          else
            { }
        );

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
            inherit
              helpers
              dotfilesDir
              home-manager
              niri
              local-skills
              anthropic-skills
              vercel-skills
              ui-ux-pro-max-skill
              ast-grep-skill
              agent-skills
              ;
          };
          modules = [
            ./nix/modules/linux
            ./nix/hosts/${host}
            ./nix/profiles/${profile}.nix
            {
              nixpkgs.overlays = [
                (mkExternalOverlay system)
                moonbit-overlay.overlays.default
                customOverlay
              ];
              nixpkgs.config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                  "claude-code"
                  "android-studio"
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
          ]
          ++ extraModules;
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
            inherit
              helpers
              dotfilesDir
              home-manager
              local-skills
              anthropic-skills
              vercel-skills
              ui-ux-pro-max-skill
              ast-grep-skill
              agent-skills
              onepassword-shell-plugins
              ;
          };
          modules = [
            ./nix/modules/darwin
            ./nix/hosts/${host}
            ./nix/profiles/darwin.nix
            {
              nixpkgs.overlays = [
                (mkExternalOverlay system)
                moonbit-overlay.overlays.default
                customOverlay
                brew-nix.overlays.default
              ];
              nixpkgs.config.allowUnfree = true;
            }
          ]
          ++ extraModules;
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        treefmt-nix.flakeModule
        inputs.git-hooks.flakeModule
      ];

      perSystem =
        {
          pkgs,
          system,
          config,
          ...
        }:
        let
          isDarwin = builtins.match ".*-darwin" system != null;
          hostname = if isDarwin then "darwin" else "nixos";
          nom = "${pkgs.nix-output-monitor}/bin/nom";
          customPkgs = import nixpkgs {
            inherit system;
            overlays = [ customOverlay ];
          };
        in
        {
          packages = {
            inherit (customPkgs)
              difit
              entire
              jj-desc
              keifu
              polycat
              pretty-ts-errors-markdown
              similarity-ts
              ;
          };
          apps = {
            build = {
              type = "app";
              program = toString (
                pkgs.writeShellScript "build" ''
                  set -e
                  echo "Building ${if isDarwin then "darwin" else "NixOS"} configuration..."
                  ${nom} build ${
                    if isDarwin then
                      ".#darwinConfigurations.${hostname}.system"
                    else
                      ".#nixosConfigurations.${hostname}.config.system.build.toplevel"
                  }
                  echo "Build successful! Run 'nix run .#switch' to apply."
                ''
              );
            };
            switch = {
              type = "app";
              program = toString (
                pkgs.writeShellScript "switch" ''
                  set -eo pipefail
                  echo "Switching to ${if isDarwin then "darwin" else "NixOS"} configuration..."
                  ${
                    if isDarwin then
                      "darwin-rebuild switch --flake .#${hostname} |& ${nom}"
                    else
                      "sudo nixos-rebuild switch --flake .#${hostname} |& ${nom}"
                  }
                  echo "Done!"
                ''
              );
            };
            fmt = {
              type = "app";
              program = toString (
                pkgs.writeShellScript "treefmt-wrapper" ''
                  exec ${config.treefmt.build.wrapper}/bin/treefmt "$@"
                ''
              );
            };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              stylua.enable = true;
              shfmt.enable = true;
            };
            settings.global.excludes = [
              ".git/**"
              "*.lock"
            ];
          };

          pre-commit = {
            check.enable = false;
            settings.hooks = {
              treefmt = {
                enable = true;
                package = config.treefmt.build.wrapper;
              };
              git-secrets = {
                enable = true;
                entry = "${pkgs.git-secrets}/bin/git-secrets --pre_commit_hook";
                language = "system";
                stages = [ "pre-commit" ];
                excludes = [ "^\.direnv/" ];
              };
            };
          };

          devShells.default = pkgs.mkShell {
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
          };
        };

      flake = {
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
    };
}
