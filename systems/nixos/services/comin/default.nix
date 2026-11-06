{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../alloy
    ../../../shared/comin/alloy.nix
    ../../../shared/comin/package.nix
  ];

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/yutakobayashidev/dotnix";
      }
    ];
  };

  # Lanzaboote scans the standard system profile, not Comin's named profile.
  # Register the deployment before the existing installer signs boot entries.
  system.build.installBootLoader =
    lib.mkIf (config.services.comin.enable && config.boot.lanzaboote.enable)
      (
        lib.mkForce (
          pkgs.writeShellScript "lanzaboote-comin-install" ''
            set -e
            ${lib.getExe' config.nix.package "nix-env"} --profile /nix/var/nix/profiles/system --set "$1"
            exec ${config.boot.loader.external.installHook} "$@"
          ''
        )
      );
}
