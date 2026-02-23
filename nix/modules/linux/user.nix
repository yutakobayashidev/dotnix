{ pkgs, username, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "adbusers"
    ];
  };

  nix.settings.allowed-users = [ username ];
  nix.settings.trusted-users = [
    "root"
    username
  ];
}
