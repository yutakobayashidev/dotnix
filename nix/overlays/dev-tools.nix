# 外部flake input由来の開発ツール
final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
{
  gogcli = prev._nix-steipete-tools.packages.${system}.gogcli;
  version-lsp =
    let
      version = "0.5.1";
      target =
        {
          "x86_64-linux" = "Linux_x86_64";
          "aarch64-darwin" = "Darwin_arm64";
        }
        .${system};
      hash =
        {
          "x86_64-linux" = "sha256-bJ9kRIxeBatKtqi+AjPJGMyZnBh3bgR+epuqa0cxEfY=";
          "aarch64-darwin" = "sha256-GLsMmrIOWBW5dS7ojH28uTnz2xZkXUZmKmmz2VMdA/I=";
        }
        .${system};
    in
    prev.stdenv.mkDerivation {
      pname = "version-lsp";
      inherit version;
      src = prev.fetchurl {
        url = "https://github.com/skanehira/version-lsp/releases/download/v${version}/version-lsp_${target}.tar.gz";
        inherit hash;
      };
      sourceRoot = ".";
      installPhase = ''
        mkdir -p $out/bin
        cp version-lsp $out/bin/version-lsp
        chmod +x $out/bin/version-lsp
      '';
    };
  ghostty = prev._ghostty.packages.${system}.default;
  repiq = prev._repiq.packages.${system}.default;
  moonbit-lsp =
    let
      moonbit-overlay = prev._moonbit-overlay;
      versions = import "${moonbit-overlay}/versions.nix" prev.lib;
      latest = versions.latest;
      target =
        {
          "x86_64-linux" = "linux-x86_64";
          "aarch64-darwin" = "darwin-aarch64";
        }
        .${system};
      hashAttr = "${target}-toolchainsHash";
    in
    prev.stdenv.mkDerivation {
      pname = "moonbit-lsp";
      version = latest.version;
      src = prev.fetchurl {
        url = "https://github.com/moonbit-community/moonbit-overlay/releases/download/${prev.lib.escapeURL latest.version}/moonbit-${target}.tar.gz";
        hash = latest.${hashAttr};
      };
      sourceRoot = ".";
      installPhase = ''
        mkdir -p $out/bin
        cp bin/moonbit-lsp $out/bin/moonbit-lsp
        chmod +x $out/bin/moonbit-lsp
      '';
    };
}
