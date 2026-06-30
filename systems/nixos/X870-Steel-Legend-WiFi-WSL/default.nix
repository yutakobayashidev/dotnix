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

  wsl = {
    enable = true;
    defaultUser = "yuta";
    wslConf = {
      automount.options = "metadata";
      boot.systemd = true;
    };
    useWindowsDriver = true;
  };

  networking.hostName = "X870-Steel-Legend-WiFi-WSL";

  my.services.tailscale.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}
