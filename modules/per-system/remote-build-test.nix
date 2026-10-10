{ inputs, ... }:

{
  perSystem =
    { lib, system, ... }:
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        remote-build = import ../../tests/remote-build.nix { inherit (inputs) nixpkgs; };
      };
    };
}
