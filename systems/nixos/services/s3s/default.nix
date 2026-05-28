{
  config,
  pkgs,
  lib,
  username,
  ...
}:
let
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      beautifulsoup4
      mmh3
      msgpack
      packaging
      requests
    ]
  );

  s3s = pkgs.stdenv.mkDerivation {
    pname = "s3s";
    version = "0.7.0-unstable-2025-08-19";

    src = pkgs.fetchFromGitHub {
      owner = "frozenpandaman";
      repo = "s3s";
      rev = "732c91e5ac9b82a413f96bc75831996f8cf4f9ea";
      hash = "sha256-o9GOmOin3wTyCL/KNa+WjMSV4RuyWea2lx5iS+57F68=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/s3s $out/bin

      cp s3s.py iksm.py utils.py $out/lib/s3s/

      substituteInPlace $out/lib/s3s/s3s.py \
        --replace-fail \
        'os.path.join(app_path, "config.txt")' \
        'os.path.join(os.getcwd(), "config.txt")'

      makeWrapper ${pythonEnv}/bin/python3 $out/bin/s3s \
        --add-flags "$out/lib/s3s/s3s.py"

      runHook postInstall
    '';
  };
in
{
  home-manager.users.${username} =
    { config, lib, ... }:
    let
      s3sConfigDir = "${config.xdg.configHome}/s3s";

      s3sConfig = {
        api_key = config.sops.placeholder."s3s-api-key";
        acc_loc = "ja-JP|JP";
        gtoken = "";
        bullettoken = "";
        session_token = "skip";
        f_gen = "https://api.imink.app/f";
      };

      nxapiS3sRefresh = pkgs.writeShellScript "nxapi-s3s-refresh" ''
        set -euo pipefail
        SESSION_TOKEN="$(${pkgs.coreutils}/bin/cat ${
          config.sops.secrets."s3s-session-token".path
        } 2>/dev/null || true)"
        if [ -z "$SESSION_TOKEN" ]; then
          echo "No session token available, skipping token refresh."
          exit 0
        fi
        export NXAPI_USER_AGENT="s3s/0.7.0"
        ${pkgs.nxapi}/bin/nxapi util update-s3s-token "${s3sConfigDir}/config.txt" --token "$SESSION_TOKEN"
      '';
    in
    {
      sops.secrets = {
        "s3s-api-key" = {
          sopsFile = ./secrets.yaml;
        };
        "s3s-session-token" = {
          sopsFile = ./secrets.yaml;
        };
      };

      sops.templates."s3s-config.txt" = {
        content = builtins.toJSON s3sConfig;
      };

      home.packages = [
        s3s
        pkgs.nxapi
      ];

      home.activation.initS3sConfig = lib.hm.dag.entryAfter [ "sops-nix" ] ''
        mkdir -p "${s3sConfigDir}"
        ${pkgs.coreutils}/bin/cp ${config.sops.templates."s3s-config.txt".path} "${s3sConfigDir}/config.txt"
        ${pkgs.coreutils}/bin/chmod 600 "${s3sConfigDir}/config.txt"
      '';

      systemd.user.services.nxapi-token = {
        Unit = {
          Description = "Refresh s3s tokens via nxapi";
        };
        Service = {
          Type = "oneshot";
          ExecStart = nxapiS3sRefresh;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      systemd.user.timers.nxapi-token = {
        Unit = {
          Description = "Periodic s3s token refresh via nxapi";
        };
        Timer = {
          OnBootSec = "1min";
          OnUnitActiveSec = "1h";
          Persistent = true;
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };

      systemd.user.services.s3s = {
        Unit = {
          Description = "s3s - Splatoon 3 battle stats uploader to stat.ink";
          After = [
            "network-online.target"
            "nxapi-token.service"
          ];
          Wants = [
            "network-online.target"
            "nxapi-token.service"
          ];
        };
        Service = {
          Type = "simple";
          Restart = "always";
          RestartSec = "30min";
          RuntimeMaxSec = "86400";
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/.config/s3s";
          ExecStart = "${lib.getExe s3s} -M 300 -r";
          WorkingDirectory = "%h/.config/s3s";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
}
