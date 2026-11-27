{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.dns64;
  corefile = pkgs.writeText "Corefile-dns64" (
    import ./dns64-corefile.nix {
      inherit lib;
      inherit (cfg)
        domains
        listenAddress
        port
        synthesisPort
        upstream
        prefix
        translateAll
        allowIPv4
        metricsAddress
        ;
    }
  );
in
{
  options.my.services.dns64 = {
    enable = lib.mkEnableOption "opt-in DNS64 endpoint, separate from Global DNS";
    domains = lib.mkOption {
      type = lib.types.listOf (lib.types.strMatching "[a-z0-9]([a-z0-9.-]*[a-z0-9])?");
      default = [ ];
      example = [
        "chatgpt.com"
        "challenges.cloudflare.com"
        "trycloudflare.com"
      ];
      description = "DNS suffixes to translate; include only domains needed by the experiment.";
    };
    listenAddress = lib.mkOption {
      type = lib.types.strMatching "[0-9a-fA-F:.]+";
      default = "127.0.0.1";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 1053;
    };
    synthesisPort = lib.mkOption {
      type = lib.types.port;
      default = 1065;
    };
    upstream = lib.mkOption {
      type = lib.types.strMatching "[0-9a-fA-F.:\\[\\]]+";
      default = "127.0.0.1:53";
    };
    prefix = lib.mkOption {
      type = lib.types.enum [ "64:ff9b:1:35::/96" ];
      default = "64:ff9b:1:35::/96";
    };
    translateAll = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    allowIPv4 = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    metricsAddress = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "127.0.0.1:9154";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.domains != [ ];
        message = "DNS64 requires explicit domain selection.";
      }
      {
        assertion = cfg.port != 53 && cfg.synthesisPort != 53 && cfg.port != cfg.synthesisPort;
        message = "DNS64 must not replace port 53 / existing Global DNS.";
      }
      {
        assertion = !(builtins.elem "." cfg.domains);
        message = "DNS64 must not translate the root zone.";
      }
    ];
    # No firewall opening, DNS override, or change to the existing coredns unit.
    systemd.services.dns64 = {
      description = "Separate opt-in DNS64 resolver";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "coredns.service"
      ];
      serviceConfig = {
        ExecStart = "${pkgs.coredns}/bin/coredns -conf ${corefile}";
        Restart = "on-failure";
        DynamicUser = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      };
    };
  };
}
