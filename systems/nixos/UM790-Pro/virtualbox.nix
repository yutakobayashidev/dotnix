{ username, ... }:

{
  virtualisation.virtualbox.host.enable = true;
  users.users.${username}.extraGroups = [ "vboxusers" ];

  # Recreate the host-only interface before applying addresses during a switch.
  systemd.services.network-addresses-vboxnet0 = {
    requires = [ "vboxnet0.service" ];
    after = [ "vboxnet0.service" ];
  };
}
