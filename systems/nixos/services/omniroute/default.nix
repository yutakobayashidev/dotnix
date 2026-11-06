{
  config,
  lib,
  pkgs,
  ...
}:
let
  stateDir = "/var/lib/omniroute";
  secretsDir = "/var/lib/omniroute-secrets";
  environmentFile = "${secretsDir}/environment";
  domain = "omniroute.home.yutakobayashi.com";
  backend = config.virtualisation.oci-containers.backend;
  containerService = "${backend}-omniroute";
in
{
  sops.secrets = {
    "omniroute/chatgpt-auth-json" = {
      sopsFile = ./auth.json;
      format = "binary";
    };
    "omniroute/opencode-go-key" = {
      sopsFile = ./secrets.yaml;
      # Keep the encrypted payload intact when moving the existing secret.
      key = "litellm/opencode-go-key";
    };
  };

  virtualisation.oci-containers.containers.omniroute = {
    image = "ghcr.io/diegosouzapw/omniroute:3.8.52@sha256:b08a12e876baa8a5ccadd1ebbe346fe7267dba3b1c9f4fd6bb02070fae41ab6c";
    ports = [ "127.0.0.1:8317:20128" ];
    volumes = [ "${stateDir}:/app/data" ];
    environmentFiles = [ environmentFile ];
    environment = {
      DATA_DIR = "/app/data";
      HOSTNAME = "0.0.0.0";
      PORT = "20128";
      REQUIRE_API_KEY = "true";
      OMNIROUTE_API_KEY = "sk-proxy";
      AUTH_COOKIE_SECURE = "true";
      NEXT_TELEMETRY_DISABLED = "1";
      TZ = "Asia/Tokyo";
    };
  };

  systemd.services = {
    omniroute-setup = {
      description = "Prepare persistent OmniRoute data and dashboard secrets";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
      };
      script = ''
        install -d -m 0700 -o 1000 -g 1000 ${stateDir}
        install -d -m 0700 ${secretsDir}
        ${lib.getExe pkgs.python3} - <<'PY'
        import secrets
        from pathlib import Path

        path = Path("${environmentFile}")
        if not path.exists():
            values = {
                "JWT_SECRET": secrets.token_hex(48),
                "API_KEY_SECRET": secrets.token_hex(32),
                "INITIAL_PASSWORD": secrets.token_hex(32),
            }
            with path.open("x") as output:
                for name, value in values.items():
                    output.write(f"{name}={value}\n")
        PY
      '';
    };

    ${containerService} = {
      requires = [ "omniroute-setup.service" ];
      after = [
        "omniroute-setup.service"
        "litellm.service"
      ];
      conflicts = [ "litellm.service" ];
      wants = [ "omniroute-bootstrap.service" ];
    };

    omniroute-bootstrap = {
      description = "Reconcile OmniRoute providers and model routing";
      requires = [ "${containerService}.service" ];
      after = [ "${containerService}.service" ];
      partOf = [ "${containerService}.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
        TimeoutStartSec = "5min";
        LoadCredential = [
          "chatgpt-auth.json:${config.sops.secrets."omniroute/chatgpt-auth-json".path}"
          "opencode-go-key:${config.sops.secrets."omniroute/opencode-go-key".path}"
        ];
        ExecStart = "${lib.getExe pkgs.python3} ${./bootstrap.py} ${./routing.json}";
      };
    };
  };

  services.traefik.dynamicConfigOptions.http = {
    routers.omniroute = {
      entryPoints = [ "websecure" ];
      rule = "Host(`${domain}`)";
      service = "omniroute";
      tls.certResolver = "letsencrypt";
    };
    services.omniroute.loadBalancer.servers = [ { url = "http://127.0.0.1:8317"; } ];
  };
}
