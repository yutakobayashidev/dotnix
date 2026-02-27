{ config, ... }:
{
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets.wifi_env.path ];
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
          psk = "$WIFI_PSK_HOME";
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
