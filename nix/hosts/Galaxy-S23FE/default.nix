{ inputs }:

inputs.nix-on-droid.lib.nixOnDroidConfiguration {
  modules = [ ../../modules/nix-on-droid ];
  pkgs = import inputs.nixpkgs {
    system = "aarch64-linux";
    overlays = [ inputs.nix-on-droid.overlays.default ];
  };
  home-manager-path = inputs.home-manager.outPath;
}
