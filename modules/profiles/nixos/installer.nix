{ lib, pkgs, ... }:

{
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager.wantedBy = [ "multi-user.target" ];

  security.sudo.wheelNeedsPassword = false;

  services = {
    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };
    getty.autologinUser = lib.mkForce "root";
  };
  users.users.root.initialPassword = "netboot";
  users.users.root.initialHashedPassword = lib.mkForce null;

  environment.systemPackages = with pkgs; [
    coreutils
    dnsmasq
    psmisc
    dvb-apps
    efibootmgr
    sbctl
    opensc
    pcsc-tools
    pciutils
    tcpdump
    usbutils
    v4l-utils
    vulnix
    llm-agents.codex
  ];
}
