{
  config,
  inputs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    ../common.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    ../desktop.nix
    ../laptop.nix
    ../../../modules/profiles/nixos/base.nix
    ../../../modules/profiles/nixos/desktop.nix
    ../../../modules/profiles/nixos/laptop.nix
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./disko.nix
    ./impermanence.nix
  ];

  dualboot.enable = true;

  ext.security.secureboot.enable = true;

  boot = {
    loader.efi.canTouchEfiVariables = true;
    initrd = {
      systemd.enable = true;
      availableKernelModules = [
        "nvme"
        "thunderbolt"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
    };
    kernelModules = [ "kvm-intel" ];
  };

  networking = {
    hostName = "ThinkPad-X1-Carbon";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  system.stateVersion = "25.11";
}
