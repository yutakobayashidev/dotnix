{
  inputs,
  username,
  config,
  ...
}:

let
  helpers = import ../modules/lib/helpers { lib = inputs.nixpkgs.lib; };
  dotfilesDir = "${
    config.home-manager.users.${username}.programs.git.settings.ghq.root
  }/github.com/yutakobayashidev/dotnix";

in
{
  home-manager = {
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
    ];
    users.${username} =
      { config, ... }:
      {
        imports = [ ../modules/profiles/home/base.nix ];
        sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
        home = {
          inherit username;
          stateVersion = "25.11";
        };
      };
  };
}
