{ inputs, ... }:
{

  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        nat64-eval = import ../../tests/nat64-eval.nix { inherit pkgs inputs; };
        dns64 = import ../../tests/dns64.nix { inherit pkgs; };
        nat64-direct = import ../../tests/nat64-warp.nix {
          inherit pkgs;
          withWarp = false;
        };
        nat64-warp = import ../../tests/nat64-warp.nix { inherit pkgs; };
      };
    };
}
