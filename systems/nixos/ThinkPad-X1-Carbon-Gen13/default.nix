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
    (modulesPath + "/installer/scan/not-detected.nix")
    ../desktop.nix
    ../laptop.nix
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  dualboot.enable = true;
  my = {
    fingerprint.enable = true;
    system.impermanence.enable = true;
    profiles = {
      base.enable = true;
      communication.enable = true;
      desktop.enable = true;
      development.enable = true;
      laptop.enable = true;
      media.enable = true;
      network.enable = true;
      productivity.enable = true;
      security.enable = true;
    };
  };

  # Tap Alt to select an input mode; holding it keeps the normal modifier behavior.
  services = {
    keyd = {
      enable = true;
      keyboards.default.settings.main = {
        leftalt = "overload(alt, muhenkan)";
        rightalt = "overload(altgr, hanja)";
      };
    };
    openssh.hostKeys = [
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
    };
  };

  i18n.inputMethod.fcitx5.settings.globalOptions = {
    "Hotkey/DeactivateKeys"."0" = "Muhenkan";
    "Hotkey/ActivateKeys"."0" = "Hangul_Hanja";
    Behavior.ShareInputState = "All";
  };

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ username ];
    };
  };

  # Enable after the first successful boot and sbctl key creation.
  ext.security.secureboot.enable = false;

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = !config.ext.security.secureboot.enable;
    };
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
    hostName = "ThinkPad-X1-Carbon-Gen13";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };

  sops.age = {
    keyFile = lib.mkForce "/persist/var/lib/sops-nix/key.txt";
    sshKeyPaths = lib.mkForce (map (key: key.path) config.services.openssh.hostKeys);
    generateKey = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  system.stateVersion = "26.11";
}
