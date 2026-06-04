{
  config,
  inputs,
  lib,
  modulesPath,
  username,
  ...
}:

{
  imports = [
    ../common.nix
    ../services/hermes-agent
    ../services/comin
    (modulesPath + "/installer/scan/not-detected.nix")
    ./virtualbox.nix
    ../desktop.nix
    ../../../modules/profiles/nixos/base.nix
    ../../../modules/profiles/nixos/desktop.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5803da04-93cf-4c24-9777-65d1432d8227";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3982-B5EB";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  networking.hostName = "UM790-Pro";
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;
  networking.resolvconf.enable = false;

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
  };

  networking.networkmanager.ensureProfiles.profiles.home-wifi = {
    connection = {
      id = "TP-Link_42B4_5G";
      type = "wifi";
      autoconnect = true;
    };
    wifi = {
      mode = "infrastructure";
      ssid = "TP-Link_42B4_5G";
    };
    wifi-security = {
      key-mgmt = "wpa-psk";
      psk = "1503c6ce57422a89725114cbf0bd291047d6ac3e80e87c7ed015fb98c2b9d428";
    };
    ipv4.method = "auto";
    ipv6 = {
      method = "auto";
      addr-gen-mode = "default";
    };
  };

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandlePowerKeyLongPress = "poweroff";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "25.11";
}
