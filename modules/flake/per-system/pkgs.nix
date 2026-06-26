{ inputs, ... }:
let
  inherit (builtins) match;
  mkPkgs =
    system:
    let
      isDarwin = match ".*-darwin" system != null;
    in
    import inputs.nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
        permittedInsecurePackages = [
          "python3.13-ecdsa-0.19.2"
        ];
      };
      overlays = [
        (_final: _prev: {
          stable = import inputs.nixpkgs-stable {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
        })
        inputs.llm-agents.overlays.default
        (_final: _prev: {
          _nix-steipete-tools = inputs.nix-steipete-tools;
          _ghostty = inputs.ghostty;
          _repiq = inputs.repiq;
          _moonbit-overlay = inputs.moonbit-overlay;
          _tree-sitter-moonbit = inputs.tree-sitter-moonbit;
        })
        inputs.gh-nippou.overlays.default
        inputs.gh-graph.overlays.default
        inputs.rustowl-flake.overlays.default
        inputs.firefox-addons.overlays.default
        inputs.nur-packages.overlays.default
        inputs.birdclaw.overlays.default
        inputs.nix-topology.overlays.default
        (import ../../../overlays/default.nix)
      ]
      ++ inputs.nixpkgs.lib.optionals isDarwin [
        inputs.brew-nix.overlays.default
      ];
    };
in
{
  _module.args.mkPkgs = mkPkgs;
}
