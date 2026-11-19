{ pkgs }:
let
  lib = pkgs.lib;
  mk =
    port: synthesisPort: translateAll: allowIPv4:
    import ../modules/features/network/nat64-warp/dns64-corefile.nix {
      inherit
        lib
        port
        synthesisPort
        translateAll
        allowIPv4
        ;
      domains = [
        "selected.test"
        "ads.test"
        "cloaked.chain.test"
      ];
      listenAddress = "127.0.0.1";
      upstream = "127.0.0.1:5353";
      prefix = "64:ff9b:1:35::/96";
      metricsAddress = null;
    };
  corefile = pkgs.writeText "Corefile-dns64-test" (
    mk 11053 11054 true true + mk 11055 11056 false true + mk 11057 11058 true false
  );
  python = pkgs.python3.withPackages (p: [ p.dnspython ]);
in
pkgs.runCommand "dns64-test"
  {
    COREDNS_SOURCE = ../systems/nixos/services/coredns;
    DNS64_CONFIG = corefile;
  }
  ''
    cp ${./test_coredns.py} test_coredns.py
    cp ${./test_dns64.py} test_dns64.py
    ${python}/bin/python test_dns64.py ${pkgs.coredns}/bin/coredns -v
    touch "$out"
  ''
