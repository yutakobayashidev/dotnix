{ inputs, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../common.nix
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

  my.profiles = {
    base.enable = true;
    development.enable = true;
    network.enable = true;
  };
  my.services.tailscale.enable = false;

  system.stateVersion = "25.11";
}
