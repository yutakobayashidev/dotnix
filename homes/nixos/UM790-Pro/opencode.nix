{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.opencode.web = {
    enable = true;
    extraArgs = [
      "--hostname"
      "100.91.91.87"
      "--port"
      "4096"
    ];
    environmentFile = config.sops.templates."opencode-web.env".path;
  };

  sops = {
    secrets.opencode-web-password = {
      sopsFile = ../../../secrets/opencode-web.yaml;
      key = "password";
    };
    templates."opencode-web.env" = {
      content = ''
        OPENCODE_PASSWORD=${config.sops.placeholder.opencode-web-password}
      '';
      mode = "0400";
    };
  };

  systemd.user.services.opencode-web = {
    Unit = {
      Requires = [ "sops-nix.service" ];
      After = [ "sops-nix.service" ];
    };
    Service = {
      ExecStartPre = pkgs.writeShellScript "opencode-web-check-password" ''
        if [ -z "''${OPENCODE_PASSWORD:-}" ]; then
          echo "OPENCODE_PASSWORD must not be empty" >&2
          exit 1
        fi
      '';
      WorkingDirectory = config.home.homeDirectory;
      UnsetEnvironment = [
        "DISPLAY"
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP"
      ];
      Environment = [
        "HOME=${config.home.homeDirectory}"
        "PATH=${
          lib.concatStringsSep ":" (
            config.home.sessionPath
            ++ [
              "/run/wrappers/bin"
              "/run/current-system/sw/bin"
            ]
          )
        }"
        "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
        "BROWSER=${pkgs.coreutils}/bin/true"
      ];
      Restart = lib.mkForce "on-failure";
      UMask = "0077";
    };
  };
}
