{ inputs, ... }:

{
  perSystem =
    { lib, system, ... }:
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        tailscale-initrd = import ../../tests/tailscale-initrd.nix {
          inherit (inputs) nixpkgs;
          inherit inputs;
        };
      };
    };
}
