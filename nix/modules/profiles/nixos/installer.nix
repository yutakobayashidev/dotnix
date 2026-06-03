{ lib, ... }:

{
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager.wantedBy = [ "multi-user.target" ];

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  users.users.root.initialPassword = "netboot";
  users.users.root.initialHashedPassword = lib.mkForce null;

  services.getty.autologinUser = lib.mkForce "root";
}
