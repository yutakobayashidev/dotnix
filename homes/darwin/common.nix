{
  inputs,
  username,
  ...
}:

let
  helpers = import ../../lib/helpers { lib = inputs.nixpkgs.lib; };
  dotfilesDir = inputs.self.outPath;

in

{
  imports = [
    inputs.home-manager.darwinModules.home-manager
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
    ]
    ++ builtins.attrValues inputs.self.modules.homeManager;
    users.${username} =
      { config, ... }:
      {
        imports = [
          ../common.nix
        ];
        sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
        home = {
          inherit username;
        };
      };
  };
}
