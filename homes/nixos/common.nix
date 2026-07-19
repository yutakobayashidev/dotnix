{
  inputs,
  username,
  ...
}:

let
  helpers = import ../../modules/lib/helpers { lib = inputs.nixpkgs.lib; };
  dotfilesDir = inputs.self.outPath;

in

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit
        inputs
        helpers
        dotfilesDir
        ;
    };
    sharedModules = [
      inputs.agent-skills.homeManagerModules.default
      inputs.nix-index-database.homeModules.nix-index
      inputs.sops-nix.homeManagerModules.sops
      inputs.self.homeManagerModules.emacs
      inputs.self.homeManagerModules.neovim
      inputs.self.homeManagerModules.vicinae
    ];
    users.${username} =
      { config, ... }:
      {
        imports = [
          ../common.nix
          ../../modules/home/discrawl
          ../../modules/profiles/home/base.nix
        ];
        sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
        home = {
          inherit username;
        };
      };
  };
}
