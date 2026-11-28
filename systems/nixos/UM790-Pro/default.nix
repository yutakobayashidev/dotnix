{
  lib,
  modulesPath,
  config,
  ...
}:

{
  imports = [
    ../common.nix
    ../services/hermes-agent
    ../services/comin
    (modulesPath + "/installer/scan/not-detected.nix")
    ./experimental-router.nix
    ./atuin-mcp.nix
    ./local-mcp.nix
    ./tinyproxy.nix
    ./codex-limit-auto-reset.nix
    ./personal-workspace-tunnel.nix
    ./virtualbox.nix
    ../desktop.nix
  ];

  sops.secrets = {
    livesync-backup-settings.sopsFile = ../../../secrets/livesync-backup-UM790-Pro.yaml;
    livesync-backup-password.sopsFile = ../../../secrets/livesync-backup-UM790-Pro.yaml;
    livesync-backup-r2-credentials.sopsFile = ../../../secrets/livesync-backup-UM790-Pro.yaml;
  };

  ext.security.secureboot.enable = true;
  nix.settings = {
    max-jobs = 4;
    cores = 4;
  };
  my = {
    nix.remoteBuild.builder.enable = true;
    profiles = {
      base.enable = true;
      communication.enable = true;
      desktop.enable = true;
      development.enable = true;
      media.enable = true;
      network.enable = true;
      productivity.enable = true;
      security.enable = true;
    };
    services.livesync-backup = {
      enable = true;
      repository = "s3:https://8b50ea3379fb9efb39ecef76cfcaa04a.r2.cloudflarestorage.com/restic-backup/UM790-Pro/livesync";
      settingsFile = config.sops.secrets.livesync-backup-settings.path;
      passwordFile = config.sops.secrets.livesync-backup-password.path;
      environmentFile = config.sops.secrets.livesync-backup-r2-credentials.path;
    };
  };

  boot = {
    loader.efi.canTouchEfiVariables = true;
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

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

  networking = {
    hostName = "UM790-Pro";
    useDHCP = lib.mkDefault true;
    resolvconf.enable = false;
    networkmanager = {
      enable = true;
      ensureProfiles.profiles.home-wifi = {
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
    };
  };

  services = {
    prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
    };
    logind.settings.Login = {
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "poweroff";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "25.11";
}
