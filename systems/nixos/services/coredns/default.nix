{ config, lib, ... }:

let
  mitmDomain = "www.mod.gov.cn";
  homeDomain = "home.yutakobayashi.com";
  tailDomain = "tail29d068.ts.net";
  b450m = "100.111.109.43";
in
{
  services.resolved.enable = false;

  services.coredns = {
    enable = true;
    config = ''
      .:53 {
        bind 127.0.0.1 ${b450m}
        forward . 8.8.8.8 1.1.1.1
        log
        errors
      }

      ${tailDomain}:53 {
        forward . 100.100.100.100
        log
        errors
      }

      ${homeDomain}:53 {
        template ANY A {
          match "(.*)\.${homeDomain}"
          answer "{{ .Name }} 300 IN A ${b450m}"
          fallthrough
        }
        template ANY AAAA {
          match "(.*)\.${homeDomain}"
          fallthrough
        }
        forward . 8.8.8.8 1.1.1.1
        log
        errors
      }

      ${mitmDomain}:53 {
        hosts {
          ${mitmDomain} ${config.networking.hostName}
        }
        log
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
