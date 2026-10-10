{ lib, ... }:

import ../../lib/mkProfile.nix { inherit lib; } {
  name = "network";

  home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages =
        with pkgs;
        [
          bandwhich
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
          (cloudflare-warp.override { headless = !config.my.profiles.desktop.enable; })
        ]
        ++ lib.optionals (config.my.profiles.desktop.enable && pkgs.stdenv.isLinux) [
          tor-browser
        ];
    };
}
