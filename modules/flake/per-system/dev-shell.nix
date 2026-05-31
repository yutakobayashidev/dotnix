{ mkPkgs, ... }:
{
  perSystem =
    { config, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      localPkgs = mkPkgs system;
    in
    {
      devShells.default = localPkgs.mkShell {
        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };
    };
}
