# 外部flake input由来の開発ツール
final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  gogcli = prev._nix-steipete-tools.packages.${system}.gogcli;
  version-lsp = prev._version-lsp.packages.${system}.default.overrideAttrs (_: {
    doCheck = false;
  });
  ghostty = prev._ghostty.packages.${system}.default;
  repiq = prev._repiq.packages.${system}.default;
}
