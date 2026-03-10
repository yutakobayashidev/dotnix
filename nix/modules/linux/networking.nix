{ ... }:
{
  networking.networkmanager.ensureProfiles = {
    profiles = {
      home-wifi = {
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
}
