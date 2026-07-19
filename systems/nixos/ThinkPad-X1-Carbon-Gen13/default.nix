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
    ../../../modules/profiles/nixos/base.nix
    ../../../modules/profiles/nixos/desktop.nix
    ../../../modules/profiles/nixos/laptop.nix
    inputs.disko.nixosModules.disko
    ./disko.nix
    ../../../modules/profiles/nixos/impermanence.nix
  ];

  dualboot.enable = true;
  my.fingerprint.enable = true;

  # Tap Alt to select an input mode; holding it keeps the normal modifier behavior.
  services.keyd = {
    enable = true;
    keyboards.default.settings.main = {
      leftalt = "overload(alt, f13)";
      rightalt = "overload(altgr, f14)";
    };
  };

  i18n.inputMethod.fcitx5.settings.globalOptions = {
    "Hotkey/DeactivateKeys"."0" = "F13";
    "Hotkey/ActivateKeys"."0" = "F14";
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

  services.openssh.hostKeys = [
    {
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  sops.age = {
    keyFile = lib.mkForce "/persist/var/lib/sops-nix/key.txt";
    sshKeyPaths = lib.mkForce (map (key: key.path) config.services.openssh.hostKeys);
    generateKey = true;
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

  system.stateVersion = "26.11";
}
