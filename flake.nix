{
  description = "yuta's NixOS & macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
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
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    nix-steipete-tools.url = "github:openclaw/nix-steipete-tools";
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
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
    deno-skills = {
      url = "github:denoland/skills";
      flake = false;
    };
    obsidian-skills = {
      url = "github:kepano/obsidian-skills";
      flake = false;
    };
    prompt-review-skill = {
      url = "github:tokoroten/prompt-review";
      flake = false;
    };
    difit-skills = {
      url = "github:yoshiko-pg/difit";
      flake = false;
    };
    agent-browser-skill = {
      url = "github:vercel-labs/agent-browser";
      flake = false;
    };
    repiq = {
      url = "github:yutakobayashidev/repiq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur-packages = {
      url = "github:yutakobayashidev/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
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
    nix-filter.url = "github:numtide/nix-filter";
    # TODO: Pinned to specific nixpkgs commit as workaround for nix-community/nix-on-droid#495
    # Issue: "getting pseudoterminal attributes: Permission denied" with nixpkgs after 2026-01-24
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/2bceeb45e516fc6956714014c92ddfdafe4c9da3";
      inputs.home-manager.follows = "home-manager";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rustowl-flake = {
      url = "github:nix-community/rustowl-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    moonbit-overlay = {
      url = "github:moonbit-community/moonbit-overlay";
      flake = false;
    };
    actrun-overlay = {
      url = "github:myuron/actrun-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tree-sitter-moonbit = {
      url = "github:moonbitlang/tree-sitter-moonbit";
      flake = false;
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://cache.numtide.com"
      "https://yuta.cachix.org"
      "https://yutakobayashidev-nur.cachix.org"
      "https://devenv.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "yuta.cachix.org-1:VGiC7m0kQjut7lp+RG/9pCRHFpzf11ELQrM2Nc2QCCk="
      "yutakobayashidev-nur.cachix.org-1:ta0cksnLcjWO+Pg4BK++GsY4frBs9oNNY9XjaQ5QJ20="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    inputs@{
      flake-parts,
      treefmt-nix,
      nixpkgs,
      nixpkgs-stable,
      llm-agents,
      nix-steipete-tools,
      ghostty,
      gh-nippou,
      gh-graph,
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
              stable = import nixpkgs-stable {
                inherit system;
                config = {
                  allowUnfree = true;
                };
              };
            })
            llm-agents.overlays.default
            (_final: _prev: {
              _nix-steipete-tools = nix-steipete-tools;
              _ghostty = ghostty;
              _repiq = inputs.repiq;
              _moonbit-overlay = inputs.moonbit-overlay;
              _tree-sitter-moonbit = inputs.tree-sitter-moonbit;
            })
            gh-nippou.overlays.default
            gh-graph.overlays.default
            inputs.rustowl-flake.overlays.default
            inputs.actrun-overlay.overlays.default
            inputs.firefox-addons.overlays.default
            inputs.nur-packages.overlays.default
            (import ./nix/overlays/default.nix)
          ]
          ++ nixpkgs.lib.optionals isDarwin [
            brew-nix.overlays.default
          ];
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./flake-module.nix
        treefmt-nix.flakeModule
        inputs.git-hooks.flakeModule
      ];

      _module.args = {
        inherit mkPkgs;
      };

      hosts = {
        B450M-Pro4 = {
          system = "x86_64-linux";
        };
        UM790-Pro = {
          system = "x86_64-linux";
        };
        X870-Stell-Legend-WiFi = {
          system = "x86_64-linux";
        };
        pi5 = {
          system = "aarch64-linux";
        };
        M2-MacBook-Air = {
          system = "aarch64-darwin";
        };
        Galaxy-S23FE = {
          system = "aarch64-linux";
          platform = "android";
        };
      };

      perSystem =
        {
          pkgs,
          config,
          ...
        }:
        let
          system = pkgs.stdenv.hostPlatform.system;
          isDarwin = builtins.match ".*-darwin" system != null;
          localPkgs = mkPkgs system;
          nom = "${localPkgs.nix-output-monitor}/bin/nom";

          isAgentCheck = ''
            IS_AI_AGENT=false
            for var in CLAUDE_CODE CLAUDECODE CODEX_SANDBOX CODEX_THREAD_ID GEMINI_CLI OPENCODE AUGMENT_AGENT GOOSE_PROVIDER CURSOR_AGENT AI_AGENT; do
              eval "val=\''${!var:-}"
              if [ -n "$val" ]; then
                IS_AI_AGENT=true
                break
              fi
            done
          '';
        in
        {
          packages = {
            inherit (localPkgs)
              difit
              git-now
              jj-desc
              keifu
              polycat
              pretty-ts-errors-markdown
              readout
              roots
              similarity-ts
              tunnelto
              waza
              ;
          };

          apps = {
            build = {
              type = "app";
              program = toString (
                localPkgs.writeShellScript "build" ''
                  set -e
                  ${isAgentCheck}

                  HOSTNAME="$(hostname)"

                  ${
                    if isDarwin then
                      ''
                        echo "Building darwin configuration for $HOSTNAME..."
                        if [ "$IS_AI_AGENT" = true ]; then
                          nix build ".#darwinConfigurations.$HOSTNAME.system"
                        else
                          ${nom} build ".#darwinConfigurations.$HOSTNAME.system"
                        fi
                      ''
                    else
                      ''
                        echo "Building NixOS configuration for $HOSTNAME..."
                        if [ "$IS_AI_AGENT" = true ]; then
                          nix build ".#nixosConfigurations.$HOSTNAME.config.system.build.toplevel"
                        else
                          ${nom} build ".#nixosConfigurations.$HOSTNAME.config.system.build.toplevel"
                        fi
                      ''
                  }

                  echo "Build successful! Run 'nix run .#switch' to apply."
                ''
              );
            };

            switch = {
              type = "app";
              program = toString (
                localPkgs.writeShellScript "switch" ''
                  set -eo pipefail
                  ${isAgentCheck}

                  HOSTNAME="$(hostname)"

                  ${
                    if isDarwin then
                      ''
                        echo "Switching to darwin configuration for $HOSTNAME..."
                        if [ "$IS_AI_AGENT" = true ]; then
                          sudo darwin-rebuild switch --flake ".#$HOSTNAME"
                        else
                          sudo darwin-rebuild switch --flake ".#$HOSTNAME" |& ${nom}
                        fi
                      ''
                    else
                      ''
                        echo "Switching to NixOS configuration for $HOSTNAME..."
                        if [ "$IS_AI_AGENT" = true ]; then
                          sudo nixos-rebuild switch --flake ".#$HOSTNAME"
                        else
                          sudo nixos-rebuild switch --flake ".#$HOSTNAME" |& ${nom}
                        fi
                      ''
                  }

                  echo "Done!"
                ''
              );
            };

            fmt = {
              type = "app";
              program = toString (
                localPkgs.writeShellScript "treefmt-wrapper" ''
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
              taplo.enable = true;
              ruff-format.enable = true;
              oxfmt = {
                enable = true;
                excludes = [
                  "nvim/template/**"
                  "nvim/lazy-lock.json"
                ];
              };
            };

            settings = {
              global.excludes = [
                ".git/**"
                "*.lock"
              ];

              formatter.gitleaks = {
                command = "${localPkgs.gitleaks}/bin/gitleaks";
                options = [
                  "detect"
                  "--no-git"
                  "--exit-code"
                  "0"
                ];
                includes = [ "*" ];
                excludes = [
                  "*.png"
                  "*.jpg"
                  "*.jpeg"
                  "*.gif"
                  "*.ico"
                  "*.pdf"
                  "*.woff"
                  "*.woff2"
                  "*.ttf"
                  "*.eot"
                  "node_modules/**"
                  ".direnv/**"
                ];
              };
            };
          };

          pre-commit = {
            check.enable = false;
            settings.hooks = {
              treefmt = {
                enable = true;
                package = config.treefmt.build.wrapper;
              };
            };
          };

          devShells.default = localPkgs.mkShell {
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
          };
        };

    };
}
