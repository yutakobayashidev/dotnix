{
  inputs,
  username,
  config,
  ...
}:

let
  helpers = import ../nix/modules/lib/helpers { lib = inputs.nixpkgs.lib; };
  dotfilesDir = "${
    config.home-manager.users.${username}.home.homeDirectory
  }/ghq/github.com/yutakobayashidev/dotnix";

  local-skills = inputs.nix-filter.lib {
    root = inputs.self;
    include = [ "agents/skills" ];
  };
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
        local-skills
        ;
    };
    sharedModules = [
      inputs.agent-skills.homeManagerModules.default
      inputs.nix-index-database.homeModules.nix-index
      inputs.sops-nix.homeManagerModules.sops
    ];
    users.${username} =
      { config, ... }:
      {
        imports = [ ../nix/modules/profiles/home/base.nix ];
        sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
        home = {
          inherit username;
          stateVersion = "25.11";
        };
      };
  };
}
