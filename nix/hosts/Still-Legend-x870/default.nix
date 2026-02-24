{ inputs, mkPkgs }:
let
  inherit (inputs)
    nixpkgs
    home-manager
    nixos-wsl
    nix-filter
    ;

  system = "x86_64-linux";

  helpers = import ../../modules/lib/helpers { lib = nixpkgs.lib; };
  dotfilesDir = "/home/yuta/ghq/github.com/yutakobayashidev/dotnix";

  local-skills = nix-filter.lib {
    root = inputs.self;
    include = [ "agents/skills" ];
  };
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs;
    username = "yuta";
  };
  modules = [
    home-manager.nixosModules.home-manager
    nixos-wsl.nixosModules.default
    ../../modules/linux
    ./hardware-configuration.nix
    ../../profiles/cli.nix
    { nixpkgs.pkgs = mkPkgs system; }
    (
      { pkgs, ... }:
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = {
            inherit
              inputs
              helpers
              dotfilesDir
              local-skills
              ;
          };
          sharedModules = [ inputs.agent-skills.homeManagerModules.default ];
          users.yuta = {
            imports = [ ../../modules/home ];
            home.homeDirectory = "/home/yuta";
          };
        };
      }
    )
  ];
}
