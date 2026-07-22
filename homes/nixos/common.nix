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
      {
        xdg.userDirs = {
          enable = true;
          createDirectories = true;
          desktop = "$HOME/Desktop";
          documents = "$HOME/Documents";
          download = "$HOME/Downloads";
          music = "$HOME/Music";
          pictures = "$HOME/Pictures";
          projects = "$HOME/Projects";
          publicShare = "$HOME/Public";
          templates = "$HOME/Templates";
          videos = "$HOME/Videos";
        };
      }
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
