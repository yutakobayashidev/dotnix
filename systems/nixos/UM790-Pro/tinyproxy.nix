{ ... }:

# HTTP proxy that lets browser automation running inside the Muse VM exit
# from this host's residential connection.
#
# Muse's managed cloud browser egresses from a datacenter IP that some
# sites (e.g. Mercari) reject at sign-in, and its egress cannot be changed.
# Instead, a Playwright/Chromium instance inside the Muse VM chains through
# the Tailscale tunnel proxy to this tinyproxy, so page traffic leaves from
# UM790-Pro's home connection.
#
# Exposure is restricted twice:
# - tinyproxy listens only on this host's Tailscale address (100.91.91.87),
#   never on LAN/WAN interfaces;
# - Allow lists only the Muse VM's Tailscale address (100.83.176.125).
# The firewall already trusts tailscale0
# (modules/features/network/tailscale.nix), so no extra port opening is
# needed.
{
  services.tinyproxy = {
    enable = true;
    settings = {
      Listen = "100.91.91.87";
      Port = 8888;
      Allow = [ "100.83.176.125" ];
      Timeout = 600;
      MaxClients = 20;
    };
  };
}
