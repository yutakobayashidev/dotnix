{
  config,
  lib,
  pkgs,
  ...
}:

let
  homeDomain = "home.yutakobayashi.com";
  tailDomain = "tail29d068.ts.net";
  tailnetAddress = "100.111.109.43";
  inherit (config.networking) hostName;
  policy = import ./policy.nix { inherit pkgs homeDomain tailDomain; };
  zones = pkgs.replaceVars ./zones.conf {
    inherit
      homeDomain
      tailDomain
      tailnetAddress
      hostName
      ;
  };
  corefile = pkgs.replaceVars ./Corefile {
    inherit policy zones tailnetAddress;
    forward = ./forward.conf;
    cache = ./cache.conf;
  };
in
{
  services = {
    resolved.enable = false;

    coredns = {
      enable = true;
      config = "import ${corefile}";
    };

    victoriametrics.prometheusConfig.scrape_configs = lib.mkIf config.my.services.monitoring.enable [
      {
        job_name = "coredns";
        scrape_interval = "15s";
        static_configs = [
          {
            targets = [ "127.0.0.1:9153" ];
            labels.host = hostName;
          }
        ];
      }
    ];

  };

  my.services.alloy.configs.coredns = ''
    loki.source.journal "coredns" {
      matches = "_SYSTEMD_UNIT=coredns.service"
      labels = {
        job = "coredns",
        host = "${hostName}",
        service = "coredns",
      }
      forward_to = [loki.write.default.receiver]
    }
  '';

  systemd.services.coredns = {
    after = [ "tailscaled-set.service" ];
    wants = [ "tailscaled-set.service" ];
    # The Tailnet address can disappear briefly while switching configurations.
    # Keep retrying until it returns instead of exhausting systemd's start limit.
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig.RestartSec = "5s";
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
