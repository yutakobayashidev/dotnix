{
  description = "yuta's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ghostty.url = "github:ghostty-org/ghostty";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  outputs = { self, nixpkgs, ghostty, home-manager, llm-agents, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./nix/configuration.nix
        ({ pkgs, ... }: {
          nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
          environment.systemPackages = [
            ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default
            llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
            llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.ccusage
            llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex
          ];
        })
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.yuta = import ./nix/home.nix;
        }
      ];
    };
  };
}
