# Entry point for the flake-parts layer: pulls in the upstream module registry
# and then auto-imports every sibling module.
{ inputs, lib, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ]
  ++ import ../../lib/collectFlakeModules.nix ./.;

  # flake-parts declares flake.nixosModules upstream, but not the darwin/home
  # equivalents; declare them here so feature modules can publish to them.
  options.flake = {
    darwinModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
    };
    homeManagerModules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
    };
  };
}
