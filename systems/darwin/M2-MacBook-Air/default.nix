{ ... }:

{
  imports = [
    ../common.nix
    ../desktop.nix
  ];

  networking.hostName = "M2-MacBook-Air";
  networking.knownNetworkServices = [ "Wi-Fi" ];

  programs = {
    _1password.enable = true;
    _1password-gui.enable = true;
  };
}
