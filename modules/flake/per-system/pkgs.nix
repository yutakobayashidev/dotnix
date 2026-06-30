{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "python3.13-ecdsa-0.19.2"
          ];
        };
        overlays = [
          inputs.nur-packages.overlays.default
        ];
      };
    };
}
