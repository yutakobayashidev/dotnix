{ pkgs }:
let
  python = pkgs.python3.withPackages (p: [ p.dnspython ]);
  policy = import ../systems/nixos/services/coredns/policy.nix {
    inherit pkgs;
    homeDomain = "home.yutakobayashi.com";
    tailDomain = "tail29d068.ts.net";
  };
in
pkgs.runCommand "coredns-policy-test"
  {
    COREDNS_SOURCE = ../systems/nixos/services/coredns;
    COREDNS_POLICY = policy;
  }
  ''
    ${python}/bin/python ${./test_coredns.py} ${pkgs.coredns}/bin/coredns -v
    touch "$out"
  ''
