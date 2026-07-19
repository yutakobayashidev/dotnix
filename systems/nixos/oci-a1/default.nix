{
  inputs,
  lib,
  ...
}:

{
  imports = [
    ../common.nix
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./impermanence.nix
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "virtio_pci"
        "virtio_scsi"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  swapDevices = [ ];

  networking.hostName = "oci-a1";
  networking.useDHCP = lib.mkDefault true;

  my = {
    profiles.base.enable = true;
    services.tailscale.enable = false;
    nixpkgs.permittedInsecurePackages = [ ];
  };
  nixpkgs.config.android_sdk.accept_license = false;

  security.sudo.wheelNeedsPassword = false;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  system.stateVersion = "25.11";
}
