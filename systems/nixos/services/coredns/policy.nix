{
  pkgs,
  homeDomain,
  tailDomain,
}:
let
  # Pin both content and revision: no network fetch or mutable list at startup.
  # Source selection inspired by https://nyanshiba.com/blog/unbound/
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  fetch = source: pkgs.fetchurl { inherit (source) url hash; };
in
pkgs.runCommand "coredns-filter-policy" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python ${./generate-policy.py} \
    --domains ${fetch sources.hagezi} \
    --cnames ${fetch sources.cnames} \
    --blocklist ${./blocklist.txt} \
    --allowlist ${./allowlist.txt} \
    --protected ${homeDomain} ${tailDomain} www.mod.gov.cn invalid \
    --output "$out"
''
