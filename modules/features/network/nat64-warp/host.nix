{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.nat64Warp;
  clients = lib.concatStringsSep ", " cfg.clients;
  rules = pkgs.writeText "nat64-host.nft" ''
    table inet dotnix_nat64
    delete table inet dotnix_nat64
    table inet dotnix_nat64 {
      counter denied { }
      chain input {
        type filter hook input priority -10; policy accept;
        iifname "${cfg.tapInterface}" ct state established,related accept
        iifname "${cfg.tapInterface}" meta l4proto ipv6-icmp accept
        iifname "${cfg.tapInterface}" counter name denied drop
      }
      chain forward {
        type filter hook forward priority -10; policy accept;
        iifname "${cfg.tapInterface}" jump from_guest
        oifname "${cfg.tapInterface}" jump to_guest
        ip6 daddr 64:ff9b:1:35::/96 counter name denied drop
      }
      chain to_guest {
        iifname "${cfg.lanInterface}" ip6 saddr { ${clients} } ip6 daddr 64:ff9b:1:35::/96 accept
        iifname "${cfg.lanInterface}" ip daddr 192.168.254.2 ct state established,related accept
        counter name denied drop
      }
      chain from_guest {
        oifname "${cfg.lanInterface}" ip6 daddr { ${clients} } meta l4proto ipv6-icmp ct state related accept
        oifname "${cfg.lanInterface}" ip6 saddr 64:ff9b:1:35::/96 ip6 daddr { ${clients} } ct state established,related accept
        ip daddr { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/3 } counter name denied drop
        oifname "${cfg.lanInterface}" ip saddr 192.168.254.2 accept
        counter name denied drop
      }
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        iifname "${cfg.tapInterface}" oifname "${cfg.lanInterface}" ip saddr 192.168.254.2 masquerade
      }
    }
  '';
  v4 = [
    "-i ${cfg.tapInterface} -o ${cfg.lanInterface} -s 192.168.254.2 -j ACCEPT"
    "-i ${cfg.lanInterface} -o ${cfg.tapInterface} -d 192.168.254.2 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
  ];
  v6 = lib.concatMap (client: [
    "-i ${cfg.lanInterface} -o ${cfg.tapInterface} -s ${client} -d 64:ff9b:1:35::/96 -j ACCEPT"
    "-i ${cfg.tapInterface} -o ${cfg.lanInterface} -d ${client} -p ipv6-icmp -m conntrack --ctstate RELATED -j ACCEPT"
    "-i ${cfg.tapInterface} -o ${cfg.lanInterface} -s 64:ff9b:1:35::/96 -d ${client} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"
  ]) cfg.clients;
  commands =
    op:
    lib.concatStringsSep "\n" (
      (map (r: "iptables -w ${op} FORWARD ${r} ${if op == "-D" then "2>/dev/null || true" else ""}") v4)
      ++ (map (
        r: "ip6tables -w ${op} FORWARD ${r} ${if op == "-D" then "2>/dev/null || true" else ""}"
      ) v6)
    );
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.clients != [ ];
        message = "NAT64 requires explicit experiment-client IPv6 prefixes.";
      }
      {
        assertion = cfg.lanInterface != cfg.tapInterface;
        message = "NAT64 LAN and TAP must differ.";
      }
      {
        assertion = config.networking.firewall.enable && !config.networking.nftables.enable;
        message = "NAT64 host integration preserves the existing iptables backend.";
      }
    ];
    networking.networkmanager.unmanaged = [ "interface-name:${cfg.tapInterface}" ];
    networking.dhcpcd.denyInterfaces = [ cfg.tapInterface ];
    networking.firewall = {
      extraCommands = ''
        ${pkgs.nftables}/bin/nft -f ${rules}
        ${commands "-D"}
        ${commands "-I"}
      '';
      extraStopCommands = commands "-D";
    };
    systemd.services.nat64-host = {
      description = "Routed NAT64 guest link and bounded policy routes";
      path = [
        pkgs.iproute2
        pkgs.nftables
      ];
      after = [ "firewall.service" ];
      wants = [ "firewall.service" ];
      before = [ "radvd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = "nat64-host";
      };
      script = ''
        ${pkgs.systemd}/bin/systemctl is-active --quiet firewall.service
        ${pkgs.python3}/bin/python ${./preflight.py} ${cfg.tapInterface} ${cfg.lanInterface}
        : > /run/nat64-host/owned
        nft -f ${rules}
        ${pkgs.python3}/bin/python ${./forwarding.py} enable ${cfg.lanInterface} ${cfg.tapInterface} /run/nat64-host/sysctls.json
        ip addr replace 192.168.254.1/30 dev ${cfg.tapInterface}
        ip -6 addr replace fd64:35::1/64 dev ${cfg.tapInterface} nodad
        ip link set ${cfg.tapInterface} up
        ip -6 route replace 64:ff9b:1:35::/96 via fd64:35::2 dev ${cfg.tapInterface} table 1064
        ip -6 rule add pref 1064 to 64:ff9b:1:35::/96 lookup 1064
        ip rule add pref 1064 from 192.168.254.2/32 lookup main
      '';
      postStop = ''
        if [ -f /run/nat64-host/owned ]; then
          ip link set ${cfg.tapInterface} down || true
          ip -6 rule del pref 1064 to 64:ff9b:1:35::/96 lookup 1064 || true
          ip rule del pref 1064 from 192.168.254.2/32 lookup main || true
          ip -6 route del 64:ff9b:1:35::/96 table 1064 || true
          ip addr del 192.168.254.1/30 dev ${cfg.tapInterface} || true
          ip -6 addr del fd64:35::1/64 dev ${cfg.tapInterface} || true
        fi
        ${pkgs.python3}/bin/python ${./forwarding.py} restore ${cfg.lanInterface} ${cfg.tapInterface} /run/nat64-host/sysctls.json
        nft delete table inet dotnix_nat64 || true
      '';
    };
    services.radvd = lib.mkIf cfg.rio.enable {
      enable = true;
      config = ''
        interface ${cfg.lanInterface} {
          AdvSendAdvert on;
          MinRtrAdvInterval 10;
          MaxRtrAdvInterval 30;
          AdvDefaultLifetime 0;
          AdvManagedFlag off;
          AdvOtherConfigFlag off;
          route 64:ff9b:1:35::/96 {
            AdvRouteLifetime 90;
            RemoveRoute on;
          };
        };
      '';
    };
    systemd.services.radvd = lib.mkIf cfg.rio.enable {
      requires = [ "nat64-host.service" ];
      after = [ "nat64-host.service" ];
      partOf = [ "nat64-host.service" ];
    };
  };
}
