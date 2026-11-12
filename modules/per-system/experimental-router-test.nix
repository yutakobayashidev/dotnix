{ inputs, ... }: {
  perSystem = { lib, system, ... }: {
    checks = lib.optionalAttrs (system == "x86_64-linux") {
      experimental-router = import ../../tests/experimental-router.nix { inherit (inputs) nixpkgs; };
    };
  };
}
