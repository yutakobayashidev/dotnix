{
  config,
  pkgs,
  lib,
  username,
  ...
}:
let
  s3sConfigDir = "/var/lib/s3s";
  s3sConfigPath = "${s3sConfigDir}/config.txt";

  s3sConfig = {
    api_key = config.sops.placeholder."s3s-api-key";
    acc_loc = "ja-JP|JP";
    gtoken = "";
    bullettoken = "";
    session_token = "skip";
    f_gen = "https://api.imink.app/f";
  };

  initS3sConfig = pkgs.writeShellScript "init-s3s-config" ''
    set -euo pipefail
    if [ ! -e "${s3sConfigPath}" ]; then
      ${pkgs.coreutils}/bin/install -m 600 ${
        config.sops.templates."s3s-config.txt".path
      } "${s3sConfigPath}"
    fi
  '';

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
    ${pkgs.nxapi}/bin/nxapi util update-s3s-token "${s3sConfigPath}" --token "$SESSION_TOKEN"
  '';
in
{
  sops.secrets = {
    "s3s-api-key" = {
      sopsFile = ./secrets.yaml;
      owner = username;
    };
    "s3s-session-token" = {
      sopsFile = ./secrets.yaml;
      owner = username;
    };
  };

  sops.templates."s3s-config.txt" = {
    content = builtins.toJSON s3sConfig;
    owner = username;
    mode = "0400";
  };

  systemd.services.nxapi-token = {
    description = "Refresh s3s tokens via nxapi";
    after = [ "sops-nix.service" ];
    wants = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = username;
      StateDirectory = "s3s";
      ExecStartPre = initS3sConfig;
      ExecStart = nxapiS3sRefresh;
    };
  };

  systemd.timers.nxapi-token = {
    description = "Periodic s3s token refresh via nxapi";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1h";
      Persistent = true;
    };
  };

  systemd.services.s3s = {
    description = "s3s - Splatoon 3 battle stats uploader to stat.ink";
    after = [
      "network-online.target"
      "nxapi-token.service"
    ];
    wants = [
      "network-online.target"
      "nxapi-token.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = username;
      StateDirectory = "s3s";
      Restart = "always";
      RestartSec = "30min";
      RuntimeMaxSec = "86400";
      ExecStartPre = initS3sConfig;
      ExecStart = "${lib.getExe pkgs.s3s} -M 300 -r";
      WorkingDirectory = s3sConfigDir;
    };
  };

  home-manager.users.${username} =
    { ... }:
    {
      home.packages = [
        pkgs.s3s
        pkgs.nxapi
      ];
    };
}
