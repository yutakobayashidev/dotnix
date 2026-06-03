{ lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager.wantedBy = [ "multi-user.target" ];

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  users.users.root.initialPassword = "netboot";
  users.users.root.initialHashedPassword = lib.mkForce null;

  services.getty.autologinUser = lib.mkForce "root";

  environment.systemPackages = with pkgs; [
    coreutils
    dnsmasq
    dvb-apps
    efibootmgr
    opensc
    pcsc-tools
    pciutils
    tcpdump
    usbutils
    v4l-utils
    llm-agents.codex
  ];
}
