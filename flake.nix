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
    gh-nippou = {
      url = "github:ryoppippi/gh-nippou";
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
      llm-agents,
      gh-nippou,
      ...
    }:
    let
      system = "x86_64-linux";

      # Overlay to add external packages to pkgs
      overlay = final: prev: {
        # llm-agents packages
        claude-code = llm-agents.packages.${system}.claude-code;
        ccusage = llm-agents.packages.${system}.ccusage;
        codex = llm-agents.packages.${system}.codex;
        # ghostty
        ghostty = ghostty.packages.${system}.default;
        # gh-nippou
        gh-nippou = gh-nippou.packages.${system}.default;
      };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./nix/configuration.nix
          {
            nixpkgs.overlays = [ overlay ];
            nixpkgs.config.allowUnfreePredicate =
              pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "claude-code" ];
          }
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.yuta = import ./nix/home;
          }
        ];
      };
    };
}
