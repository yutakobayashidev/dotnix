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
    cloudflare-skills = {
      url = "github:cloudflare/skills";
      flake = false;
    };
    hashicorp-agent-skills = {
      url = "github:hashicorp/agent-skills";
      flake = false;
    };
    deno-skills = {
      url = "github:denoland/skills";
      flake = false;
    };
    aws-agent-skills = {
      url = "github:itsmostafa/aws-agent-skills";
      flake = false;
    };
    obsidian-skills = {
      url = "github:kepano/obsidian-skills";
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
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
    nix-filter.url = "github:numtide/nix-filter";
    # TODO: Pinned to specific nixpkgs commit as workaround for nix-community/nix-on-droid#495
    # Issue: "getting pseudoterminal attributes: Permission denied" with nixpkgs after 2026-01-24
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/2bceeb45e516fc6956714014c92ddfdafe4c9da3";
      inputs.home-manager.follows = "home-manager";
    };
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
      flake-parts,
      treefmt-nix,
      nixpkgs,
      llm-agents,
      nix-steipete-tools,
      version-lsp,
      ghostty,
      gh-nippou,
      gh-graph,
      moonbit-overlay,
      brew-nix,
      ...
    }:
    let
      mkPkgs =
        system:
        let
          isDarwin = builtins.match ".*-darwin" system != null;
        in
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
          overlays = [
            (_final: _prev: {
              _llm-agents = llm-agents;
              _nix-steipete-tools = nix-steipete-tools;
              _version-lsp = version-lsp;
              _ghostty = ghostty;
            })
            gh-nippou.overlays.default
            gh-graph.overlays.default
            (import ./nix/overlays/default.nix)
          ]
          ++ nixpkgs.lib.optionals (!isDarwin) [
            moonbit-overlay.overlays.default
          ]
          ++ nixpkgs.lib.optionals isDarwin [
            brew-nix.overlays.default
          ];
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
          hostname = if isDarwin then "M2-MacBook-Air" else "UM790-Pro";
          nom = "${pkgs.nix-output-monitor}/bin/nom";
          allPkgs = mkPkgs system;
        in
        {
          packages = {
            inherit (allPkgs)
              difit
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
          UM790-Pro = import ./nix/hosts/UM790-Pro { inherit inputs mkPkgs; };
        };

        darwinConfigurations = {
          M2-MacBook-Air = import ./nix/hosts/M2-MacBook-Air { inherit inputs mkPkgs; };
        };

        nixOnDroidConfigurations = {
          Galaxy-S23FE = import ./nix/hosts/Galaxy-S23FE { inherit inputs; };
        };
      };
    };
}
