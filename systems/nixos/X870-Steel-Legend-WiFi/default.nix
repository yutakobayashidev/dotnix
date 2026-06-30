{
  lib,
  modulesPath,
  config,
  pkgs,
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

  dualboot.enable = true;

  ext.security.secureboot.enable = true;

  boot = {
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
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
    kernelModules = [
      "kvm-amd"
      "nvidia-uvm"
    ];
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

  services.xserver.videoDrivers = [ "nvidia" ];

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        config.boot.kernelPackages.nvidiaPackages.stable
      ];
    };
    nvidia-container-toolkit.enable = true;
  };

  system.stateVersion = "25.11";
}
