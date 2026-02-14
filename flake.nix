{
  description = "yuta's NixOS configuration";

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
      ...
    }:
    let
      system = "x86_64-linux";

      # Helper functions for home-manager
      helpers = import ./nix/modules/lib/helpers { lib = nixpkgs.lib; };

      # Dotfiles directory path
      dotfilesDir = "/home/yuta/ghq/github.com/yutakobayashidev/dotnix";

      # Overlay to add external packages to pkgs
      overlay = final: prev: {
        # llm-agents packages
        claude-code = llm-agents.packages.${system}.claude-code;
        ccusage = llm-agents.packages.${system}.ccusage;
        codex = llm-agents.packages.${system}.codex;
        opencode = llm-agents.packages.${system}.opencode;
        vibe-kanban = llm-agents.packages.${system}.vibe-kanban;
        # ghostty
        ghostty = ghostty.packages.${system}.default;
        # version-lsp
        version-lsp = version-lsp.packages.${system}.default.overrideAttrs (oldAttrs: {
          doCheck = false;
        });
        # gh-nippou (temporarily disabled due to hash mismatch)
        # gh-nippou = gh-nippou.packages.${system}.default;
        # pretty-ts-errors-markdown
        pretty-ts-errors-markdown = prev.callPackage ./nix/packages/pretty-ts-errors-markdown.nix { };
        # difit
        difit = prev.callPackage ./nix/packages/difit.nix { };
        # aqua
        aqua = prev.callPackage ./nix/packages/aqua.nix { };
        # jj-desc
        jj-desc = prev.callPackage ./nix/packages/jj-desc.nix { };
        # entire
        entire = prev.callPackage ./nix/packages/entire.nix { };
        # polycat
        polycat = prev.callPackage ./nix/packages/polycat.nix { };
      };

      # mkSystem helper function
      mkSystem =
        {
          host,
          system,
          profile,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit helpers dotfilesDir home-manager niri;
          };
          modules = [
            ./nix/modules/core
            ./nix/hosts/${host}
            ./nix/profiles/${profile}.nix
            {
              nixpkgs.overlays = [ overlay ];
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
    };
}
