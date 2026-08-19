{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "network";

  home =
    { lib, pkgs, ... }:
    {
      home.packages =
        with pkgs;
        [
          bandwhich
          cloudflare-warp
          cloudflared
          dnsutils
          gping
          nostui
          ooniprobe-cli
          speedtest-cli
          wireguard-tools
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          proton-vpn-cli
          tor-browser
        ];
    };
}
