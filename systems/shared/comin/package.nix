{ inputs, pkgs, ... }:

{
  services.comin.package =
    inputs.comin.packages.${pkgs.stdenv.hostPlatform.system}.comin.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [ ./pending-generation.patch ];
        vendorHash = "sha256-AvEwuroaTVmBi0kNgzhbLNkbJjhsPJh21xPLh5EmbTY=";
        doCheck = true;
        checkPhase = ''
          runHook preCheck
          go test ./internal/store ./internal/builder
          runHook postCheck
        '';
      });
}
