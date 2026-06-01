{ ... }:

{
  imports = [
    ../common.nix
    ../desktop.nix
  ];

  networking.hostName = "M2-MacBook-Air";
  networking.knownNetworkServices = [ "Wi-Fi" ];
}
