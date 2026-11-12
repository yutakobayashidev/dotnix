{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.experimentalRouter;
  iface = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9_.-]{0,14}";
  # A single /24 deliberately keeps DHCP and validation small.
  prefix = "10.77.${toString cfg.subnetId}";
  subnet = "${prefix}.0/24";
  gateway = "${prefix}.1";
  rules = pkgs.writeText "experimental-router.nft" ''
    table inet dotnix_experimental_router
    delete table inet dotnix_experimental_router
    table inet dotnix_experimental_router {
      counter input_drop { }
      counter forward_drop { }
      set private_v4 {
        type ipv4_addr; flags interval;
        elements = { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8,
          169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/3 }
      }
      chain input {
        type filter hook input priority -10; policy accept;
        iifname "${cfg.lanInterface}" meta nfproto ipv4 udp sport 68 udp dport 67 accept
        iifname "${cfg.lanInterface}" ip saddr ${subnet} ip daddr ${gateway} udp dport 53 accept
        iifname "${cfg.lanInterface}" ip saddr ${subnet} ip daddr ${gateway} tcp dport 53 accept
        iifname "${cfg.lanInterface}" ip saddr ${subnet} ip daddr ${gateway} icmp type echo-request accept
        iifname "${cfg.lanInterface}" counter name input_drop drop
      }
      chain forward {
        type filter hook forward priority -10; policy accept;
        iifname "${cfg.lanInterface}" jump from_lan
        oifname "${cfg.lanInterface}" jump to_lan
      }
      chain from_lan {
        meta nfproto ipv6 counter name forward_drop drop
        ct state invalid counter name forward_drop drop
        ip saddr != ${subnet} counter name forward_drop drop
        ip daddr @private_v4 counter name forward_drop drop
        oifname "${cfg.wanInterface}" accept
        counter name forward_drop drop
      }
      chain to_lan {
        meta nfproto ipv4 iifname "${cfg.wanInterface}" ip daddr ${subnet} ct state established,related accept
        counter name forward_drop drop
      }
      chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        iifname "${cfg.lanInterface}" oifname "${cfg.wanInterface}" ip saddr ${subnet} masquerade
      }
    }
  '';
  # Docker may set FORWARD policy DROP. These narrow accepts run only after
  # the nftables guard (priority -10); they do not replace Docker's chains.
  forwardRules = [
    "-i ${cfg.lanInterface} -o ${cfg.wanInterface} -s ${subnet} -j ACCEPT"
    "-i ${cfg.wanInterface} -o ${cfg.lanInterface} -d ${subnet} -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
  ];
in
{
  options.my.services.experimentalRouter = {
    enable = lib.mkEnableOption "isolated experimental IPv4 router (requires deployment approval)";
    wanInterface = lib.mkOption {
      type = iface;
      default = "wlp2s0";
    };
    lanInterface = lib.mkOption {
      type = iface;
      default = "enp1s0";
    };
    subnetId = lib.mkOption {
      type = lib.types.ints.between 0 255;
      default = 10;
      description = "Third octet of the dedicated 10.77.X.0/24 LAN.";
    };
    upstreamDNS = lib.mkOption {
      type = lib.types.strMatching "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+";
      default = "100.111.109.43";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.wanInterface != cfg.lanInterface;
        message = "Experimental router WAN and LAN must differ.";
      }
      {
        assertion = config.networking.firewall.enable && !config.networking.nftables.enable;
        message = "Experimental router currently integrates with the existing iptables firewall; do not migrate the host backend implicitly.";
      }
      {
        assertion = !(builtins.elem cfg.lanInterface config.networking.firewall.trustedInterfaces);
        message = "Experimental LAN must not be trusted.";
      }
    ];
    networking.networkmanager.unmanaged = [ "interface-name:${cfg.lanInterface}" ];
    networking.dhcpcd.denyInterfaces = [ cfg.lanInterface ];
    networking.interfaces.${cfg.lanInterface}.useDHCP = false;
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    # Do not change global IPv6 forwarding: Tailscale already uses it.
    systemd.network.enable = true;
    # WAN readiness remains owned by NetworkManager; an unplugged lab LAN must not delay Docker.
    systemd.network.wait-online.enable = lib.mkDefault false;
    systemd.network.networks."20-experimental-lan" = {
      matchConfig.Name = cfg.lanInterface;
      address = [ "${gateway}/24" ];
      linkConfig.RequiredForOnline = false;
      networkConfig = {
        DHCP = "no";
        DHCPServer = true;
        IPv4Forwarding = true;
        IPv6Forwarding = false;
        IPv6AcceptRA = false;
        IPv6SendRA = false;
        LinkLocalAddressing = "no";
        ConfigureWithoutCarrier = true;
      };
      dhcpServerConfig = {
        PoolOffset = 100;
        PoolSize = 100;
        EmitRouter = true;
        Router = gateway;
        EmitDNS = true;
        DNS = gateway;
        DefaultLeaseTimeSec = "1h";
      };
    };
    services.dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      settings = {
        interface = cfg.lanInterface;
        except-interface = "lo";
        listen-address = gateway;
        bind-dynamic = true;
        no-resolv = true;
        no-hosts = true;
        server = [ cfg.upstreamDNS ];
        cache-size = 0;
      };
    };
    networking.firewall.interfaces.${cfg.lanInterface} = {
      allowedUDPPorts = [
        53
        67
      ];
      allowedTCPPorts = [ 53 ];
    };
    networking.firewall.extraCommands =
      "PATH=${pkgs.iproute2}/bin:$PATH ${pkgs.python3}/bin/python3 ${./preflight.py} ${cfg.lanInterface} ${cfg.wanInterface} ${subnet}\n"
      + "${pkgs.nftables}/bin/nft -f ${rules}\n"
      + lib.concatMapStringsSep "\n" (
        r: "iptables -w -C FORWARD ${r} 2>/dev/null || iptables -w -I FORWARD 1 ${r}"
      ) forwardRules;
    networking.firewall.extraStopCommands = lib.concatMapStringsSep "\n" (
      r: "iptables -w -D FORWARD ${r} 2>/dev/null || true"
    ) forwardRules;
    systemd.services.experimental-router-firewall = {
      description = "Isolated nftables guard and NAT for the experimental LAN";
      wantedBy = [ "multi-user.target" ];
      before = [
        "systemd-networkd.service"
        "dnsmasq.service"
      ];
      after = [ "firewall.service" ];
      requires = [ "firewall.service" ];
      path = [
        pkgs.nftables
        pkgs.iproute2
      ];
      preStart = "${pkgs.python3}/bin/python3 ${./preflight.py} ${cfg.lanInterface} ${cfg.wanInterface} ${subnet}";
      reloadIfChanged = true;
      reload = "nft -f ${rules}";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = "nft -f ${rules}";
      # Close the link before removing its guard, including rollback/disable.
      preStop = "ip link set dev ${cfg.lanInterface} down || true";
      postStop = "nft delete table inet dotnix_experimental_router || true";
    };
    # Prevent socket activation from resurrecting networkd during rollback.
    systemd.sockets.systemd-networkd.partOf = [ "experimental-router-firewall.service" ];
    systemd.services.systemd-networkd = {
      requires = [ "experimental-router-firewall.service" ];
      after = [ "experimental-router-firewall.service" ];
    };
    systemd.services.dnsmasq = {
      requires = [ "experimental-router-firewall.service" ];
      after = [ "experimental-router-firewall.service" ];
    };
    environment.etc."experimental-router.nft".source = rules;
  };
}
