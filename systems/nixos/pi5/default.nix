{
  inputs,
  lib,
  ...
}:

{
  imports = [
    ../common.nix
    ../services/comin
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
  ];

  boot.loader.generic-extlinux-compatible.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  networking.hostName = "pi5";
  networking.useDHCP = lib.mkDefault true;

  my = {
    profiles.base.enable = true;
    services.tailscale.enable = false;
    nixpkgs.permittedInsecurePackages = [ ];
  };
  nixpkgs.config.android_sdk.accept_license = false;

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  system.stateVersion = "25.11";
}
