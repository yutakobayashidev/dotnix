{ inputs, lib, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../common.nix
    ../../../modules/profiles/nixos/base.nix
    (
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.cudatoolkit ];
      }
    )
  ];

  wsl.enable = true;
  wsl.defaultUser = "yuta";
  wsl.wslConf = {
    automount.options = "metadata";
    boot.systemd = true;
  };
  wsl.useWindowsDriver = true;

  networking.hostName = "X870-Steel-Legend-WiFi";

  my.services.tailscale.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}
