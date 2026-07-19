{ ... }:

{
  imports = [
    ../common.nix
    ../desktop.nix
  ];

  networking.hostName = "M2-MacBook-Air";
  networking.knownNetworkServices = [ "Wi-Fi" ];
  my.profiles = {
    base.enable = true;
    desktop.enable = true;
    development.enable = true;
    media.enable = true;
    network.enable = true;
  };

  programs = {
    _1password.enable = true;
    _1password-gui.enable = true;
  };
}
