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
        coredns = import ../../tests/coredns.nix { inherit pkgs; };
      };
    };
}
