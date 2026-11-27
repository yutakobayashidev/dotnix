{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.nat64Guest;
  publicDeny = "0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/3";
  exit = if cfg.warp.enable then cfg.warp.interface else cfg.uplink;
in
{
  options.my.services.nat64Guest = {
    enable = lib.mkEnableOption "isolated NAT64 translator";
    uplink = lib.mkOption {
      type = lib.types.str;
      default = "eth0";
    };
    clients = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    gateway4 = lib.mkOption {
      type = lib.types.str;
      default = "192.168.254.1";
    };
    gateway6 = lib.mkOption {
      type = lib.types.str;
      default = "fd64:35::1";
    };
    mtu = lib.mkOption {
      type = lib.types.ints.between 1280 1500;
      default = 1280;
    };
    warp = {
      enable = lib.mkEnableOption "official WARP daemon (no automatic enrollment or connect)";
      interface = lib.mkOption {
        type = lib.types.str;
        default = "CloudflareWARP";
      };
      installClient = lib.mkOption {
        type = lib.types.bool;
        default = true;
        internal = true;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.clients != [ ];
        message = "NAT64 requires explicit client IPv6 prefixes.";
      }
    ];
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 0;
    };
    networking.firewall.checkReversePath = false;
    networking.nftables.enable = true;
    services.tayga = {
      enable = true;
      tunDevice = "nat64";
      ipv4 = {
        address = "192.0.2.1";
        router.address = "192.0.2.2";
        pool = {
          address = "192.0.2.0";
          prefixLength = 24;
        };
      };
      ipv6 = {
        address = "fd64:35::3";
        router.address = "fd64:35::4";
        pool = {
          address = "64:ff9b:1:35::";
          prefixLength = 96;
        };
      };
    };
    networking.interfaces.nat64.mtu = cfg.mtu;
    # Pin return paths outside any routes subsequently installed by warp-svc.
    networking.interfaces.${cfg.uplink}.ipv6.routes = map (client: {
      address = builtins.head (lib.splitString "/" client);
      prefixLength = lib.toInt (builtins.elemAt (lib.splitString "/" client) 1);
      via = cfg.gateway6;
    }) cfg.clients;
    networking.nftables.tables.nat64_guard = {
      family = "inet";
      content = ''
        counter translated { }
        counter denied { }
        chain forward {
          type filter hook forward priority -10; policy drop;
          ct state invalid counter name denied drop
          iifname "${cfg.uplink}" ip6 saddr { ${lib.concatStringsSep ", " cfg.clients} } ip6 daddr 64:ff9b:1:35::/96 oifname "nat64" accept
          iifname "nat64" ip6 daddr { ${lib.concatStringsSep ", " cfg.clients} } oifname "${cfg.uplink}" meta l4proto ipv6-icmp ct state related accept
          iifname "nat64" ip6 saddr 64:ff9b:1:35::/96 ip6 daddr { ${lib.concatStringsSep ", " cfg.clients} } oifname "${cfg.uplink}" ct state established,related accept
          iifname "nat64" ip daddr { ${publicDeny} } counter name denied drop
          iifname "nat64" ip saddr 192.0.2.0/24 oifname "${exit}" counter name translated accept
          iifname "${exit}" ip daddr 192.0.2.0/24 oifname "nat64" ct state established,related accept
          counter name denied drop
        }
        chain mss {
          type filter hook forward priority mangle; policy accept;
          oifname "${exit}" ip saddr 192.0.2.0/24 tcp flags & (syn|rst) == syn tcp option maxseg size > ${toString (cfg.mtu - 60)} tcp option maxseg size set ${toString (cfg.mtu - 60)}
        }
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          iifname "nat64" oifname "${exit}" ip saddr 192.0.2.0/24 masquerade
        }
      '';
    };
    # A permanent unreachable route prevents fallback to the underlay during
    # interface removal, reconnect, or failure of the route maintenance unit.
    systemd.services.nat64-egress = {
      wantedBy = [ "multi-user.target" ];
      before = [ "tayga.service" ];
      after = [
        "network.target"
        "nftables.service"
      ];
      requires = [ "nftables.service" ];
      path = [
        pkgs.iproute2
        pkgs.coreutils
        pkgs.gnugrep
      ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 1;
      };
      preStart = ''
        ip route replace unreachable default metric 32767 table 1064
        ip rule del pref 1064 iif nat64 table 1064 2>/dev/null || true
        ip rule add pref 1064 iif nat64 table 1064
        ${lib.concatMapStringsSep "\n" (client: ''
          ip -6 route replace ${client} via ${cfg.gateway6} dev ${cfg.uplink} table 1064
          ip -6 rule del pref 1064 to ${client} lookup 1064 2>/dev/null || true
          ip -6 rule add pref 1064 to ${client} lookup 1064
        '') cfg.clients}
      '';
      script = ''
        while true; do
          if ip -4 address show dev ${exit} scope global 2>/dev/null | grep -q 'inet '; then
            ip route replace default ${
              lib.optionalString (!cfg.warp.enable) "via ${cfg.gateway4}"
            } dev ${exit} metric 10 table 1064
          else
            ip route del default metric 10 table 1064 2>/dev/null || true
          fi
          sleep 1
        done
      '';
      # Keep unreachable/rule until the guest shuts down. No fallback on stop.
      postStop = "ip route del default metric 10 table 1064 2>/dev/null || true";
    };
    systemd.services.tayga = {
      requires = [ "nat64-egress.service" ];
      after = [ "nat64-egress.service" ];
    };
    services.cloudflare-warp = lib.mkIf (cfg.warp.enable && cfg.warp.installClient) {
      enable = true;
      package = pkgs.cloudflare-warp.override { headless = true; };
      openFirewall = false;
    };
    # Registration files are generated in the persistent private guest volume,
    # never interpolated into a derivation. No activation script registers WARP.
    systemd.tmpfiles.rules = lib.mkIf cfg.warp.enable [ "d /var/lib/cloudflare-warp 0700 root root -" ];
  };
}
