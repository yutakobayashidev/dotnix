{ inputs, ... }:

{
  flake.modules.nixos.omniroute =
    { pkgs, ... }:
    {
      imports = [
        "${inputs.omniroute-nixpkgs}/nixos/modules/services/web-apps/omniroute.nix"
      ];

      services.omniroute.package =
        (pkgs.callPackage "${inputs.omniroute-nixpkgs}/pkgs/by-name/om/omniroute/package.nix" { })
        .overrideAttrs
          (old: {
            # Next.js otherwise starts 15 page-data workers on UM790, ignoring
            # the Nix builder's four-core allocation.
            postPatch = (old.postPatch or "") + ''
              substituteInPlace next.config.mjs \
                --replace-fail 'experimental: {' 'experimental: { cpus: 2,'
            '';
          });
    };
}
