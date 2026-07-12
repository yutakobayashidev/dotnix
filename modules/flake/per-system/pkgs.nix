{ inputs, ... }:
let
  localOverlays = import ../../../overlays { inherit inputs; };
in
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "python3.14-ecdsa-0.19.2"
          ];
        };
        overlays = [
          (
            _final: prev:
            let
              inherit (prev.stdenv.hostPlatform) system;
            in
            {
              moonbit-lsp =
                let
                  versions = import "${inputs.moonbit-overlay}/versions.nix" prev.lib;
                  inherit (versions) latest;
                  targets = {
                    x86_64-linux = "linux-x86_64";
                    aarch64-linux = "linux-aarch64";
                    aarch64-darwin = "darwin-aarch64";
                  };
                  target = targets.${system} or null;
                  hashAttr = if target != null then "${target}-toolchainsHash" else null;
                in
                if target != null && builtins.hasAttr hashAttr latest then
                  prev.stdenv.mkDerivation {
                    pname = "moonbit-lsp";
                    inherit (latest) version;
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
                  }
                else
                  null;
              version-lsp = inputs.version-lsp.packages.${system}.default;
            }
          )
          inputs.rustowl-flake.overlays.default
          inputs.nur-packages.overlays.default
          localOverlays.stable
          localOverlays.llm-agents
          localOverlays.patches
        ];
      };
    };
}
