{ pkgs, home-manager, helpers, dotfilesDir, ... }:

{
  imports = [ home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit helpers dotfilesDir; };
    users.yuta = import ./../home;
  };

  users.users.yuta = {
    isNormalUser = true;
    description = "yuta";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
  };

  nix.settings.allowed-users = [ "yuta" ];
  nix.settings.trusted-users = [ "root" "yuta" ];
}
