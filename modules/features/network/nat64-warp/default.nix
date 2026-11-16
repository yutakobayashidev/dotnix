_: {
  flake.modules.nixos.nat64-warp = import ./module.nix;
  flake.modules.nixos.dns64 = import ./dns64.nix;
}
