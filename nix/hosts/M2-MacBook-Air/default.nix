{ inputs, mkPkgs }:
let
  inherit (inputs)
    nixpkgs
    nix-darwin
    home-manager
    nix-filter
    ;

  system = "aarch64-darwin";

  helpers = import ../../modules/lib/helpers { lib = nixpkgs.lib; };
  dotfilesDir = "/Users/yuta/ghq/github.com/yutakobayashidev/dotnix";

  local-skills = nix-filter.lib {
    root = inputs.self;
    include = [ "agents/skills" ];
  };
in
nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = {
    inherit inputs;
    username = "yuta";
  };
  modules = [
    ../../modules/darwin
    ./configuration.nix
    ../../profiles/darwin.nix
    { nixpkgs.pkgs = mkPkgs system; }
    {
      imports = [ home-manager.darwinModules.home-manager ];

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
        sharedModules = [
          inputs.agent-skills.homeManagerModules.default
          inputs.nix-index-database.hmModules.nix-index
        ];
        users.yuta =
          { pkgs, ... }:
          {
            imports = [
              ../../modules/home
              inputs.onepassword-shell-plugins.hmModules.default
            ];
            home.homeDirectory = "/Users/yuta";
            programs._1password-shell-plugins = {
              enable = true;
              plugins = with pkgs; [
                gh
                awscli2
              ];
            };
          };
      };

      users.users.yuta.home = "/Users/yuta";

      nix.settings.trusted-users = [
        "root"
        "yuta"
      ];
    }
  ];
}
