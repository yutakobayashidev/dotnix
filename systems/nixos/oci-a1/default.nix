{
  inputs,
  lib,
  ...
}:

{
  imports = [
    ../common.nix
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
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

  security.sudo.wheelNeedsPassword = false;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  system.stateVersion = "25.11";
}
