{ pkgs, home-manager, helpers, dotfilesDir, niri, ... }:

{
  imports = [ home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit helpers dotfilesDir niri; };
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
      "adbusers"
    ];
  };

  nix.settings.allowed-users = [ "yuta" ];
  nix.settings.trusted-users = [ "root" "yuta" ];
}
