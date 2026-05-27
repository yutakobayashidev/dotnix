{ pkgs, ... }:
let
  rip = pkgs.writeShellScriptBin "rip" ''
    exec ${pkgs.whipper}/bin/whipper cd rip \
      -O /srv/bulk/music/_inbox \
      -U \
      --cdr \
      -C complete \
      "$@"
  '';
in
{
  home.packages = [ pkgs.whipper rip ];
}
