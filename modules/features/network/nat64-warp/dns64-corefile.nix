# Keep suppression outside the synthesizer: its internal A lookup must succeed.
{
  lib,
  domains,
  listenAddress,
  port,
  synthesisPort,
  upstream,
  prefix,
  translateAll,
  allowIPv4,
  metricsAddress,
}:
let
  common = ''
    bind ${listenAddress}
    errors
  '';
in
''
  .:${toString port} {
    ${common}
    forward . ${upstream}
  }
  ${lib.concatMapStringsSep " " (d: "${d}:${toString port}") domains} {
    ${common}
    template IN A {
      rcode NOERROR
    }
    template IN HTTPS {
      rcode NOERROR
    }
    template IN SVCB {
      rcode NOERROR
    }
    rewrite type ANY HINFO
    template IN HINFO {
      rcode NOERROR
    }
    rewrite ttl regex (.*) 0-30
    forward . 127.0.0.1:${toString synthesisPort}
  }
  .:${toString synthesisPort} {
    bind 127.0.0.1
    errors
    ${lib.optionalString (metricsAddress != null) "prometheus ${metricsAddress}"}
    dns64 {
      prefix ${prefix}
      ${lib.optionalString translateAll "translate_all"}
      ${lib.optionalString allowIPv4 "allow_ipv4"}
    }
    forward . ${upstream}
  }
''
