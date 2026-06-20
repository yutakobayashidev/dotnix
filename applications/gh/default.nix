{ lib, pkgs, ... }:

let
  ghWrapper = pkgs.writeShellScriptBin "gh" ''
    set -eu

    if [ -z "''${GH_TOKEN:-}" ] && [ -z "''${GITHUB_TOKEN:-}" ]; then
      GH_TOKEN="$(${lib.getExe pkgs.ghtkn} get)"
      export GH_TOKEN
    fi

    exec ${lib.getExe pkgs.gh} "$@"
  '';
in
{
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = false;
    extensions = [
      pkgs.gh-graph
      pkgs.gh-nippou
      pkgs.gh-dash
      pkgs.gh-actions-cache
      pkgs.gh-poi
      pkgs.gh-notify
      pkgs.gh-do
    ];
  };

  home.packages = with pkgs; [
    (lib.hiPrio ghWrapper)
    ghq
    tea
    ghtkn
  ];
}
