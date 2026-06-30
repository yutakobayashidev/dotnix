{
  lib,
  modulesPath,
  config,
  ...
}:

{
  imports = [
    ../common.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    ../desktop.nix
    ../../../modules/profiles/nixos/base.nix
    ../../../modules/profiles/nixos/desktop.nix
  ];

  ext.security.secureboot.enable = true;

  boot = {
    loader.efi.canTouchEfiVariables = true;
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "ahci"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

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

  swapDevices = [ ];

  networking = {
    hostName = "X870-Steel-Legend-WiFi";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
  };

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "25.11";
}
