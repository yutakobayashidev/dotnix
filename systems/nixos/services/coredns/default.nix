{ config, lib, ... }:

let
  mitmDomain = "www.mod.gov.cn";
  homeDomain = "home.yutakobayashi.com";
  tailDomain = "tail29d068.ts.net";
  b450m = "100.111.109.43";
  inherit (config.networking) hostName;
in
{
  services.resolved.enable = false;

  services.coredns = {
    enable = true;
    config = ''
      .:53 {
        bind 127.0.0.1 ${b450m}
        forward . 8.8.8.8 1.1.1.1
        prometheus 127.0.0.1:9153
        log . {
          class denial error
        }
        errors
      }

      ${tailDomain}:53 {
        bind 127.0.0.1 ${b450m}
        forward . 100.100.100.100
        prometheus 127.0.0.1:9153
        log . {
          class denial error
        }
        errors
      }

      ${homeDomain}:53 {
        bind 127.0.0.1 ${b450m}
        # Cover the zone apex and all subdomains on the Tailnet.
        template ANY A {
          answer "{{ .Name }} 300 IN A ${b450m}"
        }
        template ANY AAAA {
          rcode NOERROR
        }
        forward . 8.8.8.8 1.1.1.1
        prometheus 127.0.0.1:9153
        log . {
          class denial error
        }
        errors
      }

      ${mitmDomain}:53 {
        bind 127.0.0.1 ${b450m}
        hosts {
          ${mitmDomain} ${hostName}
        }
        prometheus 127.0.0.1:9153
        log . {
          class denial error
        }
        errors
      }
    '';
  };

  services.victoriametrics.prometheusConfig.scrape_configs =
    lib.mkIf config.my.services.monitoring.enable
      [
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
