{
  config,
  inputs,
  lib,
  modulesPath,
  ...
}:

# Public VPS for Mastodon (fedi.yutakobayashi.com). OpenTofu creates the instance
# and nixos-anywhere installs this configuration; see infra/vultr/fedi/README.md.
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../common.nix
    ../services/comin
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./mastodon.nix
  ];

  boot = {
    # The partition layout boots with either legacy BIOS or UEFI firmware.
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    initrd.availableKernelModules = [
      "ahci"
      "sd_mod"
      "sr_mod"
      "virtio_blk"
      "virtio_pci"
      "virtio_scsi"
    ];
  };

  # The current 1 GiB VPS ran out of memory while building Mastodon's assets.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4 * 1024;
    }
  ];

  networking = {
    hostName = "vultr-fedi";
    useDHCP = lib.mkDefault true;
    nftables.enable = true;
    # Nothing listens publicly: HTTP(S) arrives through the Cloudflare Tunnel and
    # SSH through Tailscale SSH.
    firewall.allowedTCPPorts = lib.mkForce [ ];
  };

  my = {
    profiles.base.enable = true;
    services.cloudflared-tunnel = {
      enable = true;
      # TODO: UUID of the tunnel to be created in tofu-configuration.
      id = "00000000-0000-0000-0000-000000000000";
      credentialsFile = config.sops.secrets.cloudflared-tunnel.path;
    };
  };

  # TODO: ./secrets.yaml holds CHANGEME placeholders encrypted for the ThinkPad
  # only. Fill in real values and add this host's age recipient during provisioning.
  sops.secrets.cloudflared-tunnel.sopsFile = ./secrets.yaml;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.11";
}
