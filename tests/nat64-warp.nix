{
  pkgs,
  withWarp ? true,
}:
let
  inherit (pkgs) lib;
  feature = ../modules/features/network/nat64-warp;
  addr4 = address: {
    inherit address;
    prefixLength = 24;
  };
  addr6 = address: {
    inherit address;
    prefixLength = 64;
  };
in
pkgs.testers.runNixOSTest {
  name = if withWarp then "nat64-warp" else "nat64-direct";
  defaults = {
    networking.useDHCP = false;
    virtualisation.interfaces.eth1.assignIP = false;
    environment.systemPackages = [
      pkgs.curl
      pkgs.tcpdump
      pkgs.wireguard-tools
      pkgs.nftables
      pkgs.iptables
    ];
    virtualisation.memorySize = 512;
  };
  nodes = {
    client = {
      virtualisation.interfaces.eth1.vlan = 1;
      networking.interfaces.eth1 = {
        ipv4.addresses = [ (addr4 "203.0.113.10") ];
        ipv6.addresses = [ (addr6 "2001:db8:1::10") ];
      };
      networking.defaultGateway = "203.0.113.2";
      networking.defaultGateway6 = {
        address = "2001:db8:1::2";
        interface = "eth1";
      };
      boot.kernel.sysctl = {
        "net.ipv6.conf.eth1.accept_ra" = 2;
        "net.ipv6.conf.eth1.accept_ra_rt_info_max_plen" = 128;
      };
    };
    host = {
      imports = [
        (feature + /options.nix)
        (feature + /host.nix)
      ];
      virtualisation.interfaces.eth1.vlan = 1;
      virtualisation.interfaces.eth2.vlan = 2;
      virtualisation.interfaces.eth2.assignIP = false;
      networking.interfaces.eth1 = {
        ipv4.addresses = [ (addr4 "203.0.113.1") ];
        ipv6.addresses = [ (addr6 "2001:db8:1::1") ];
      };
      networking.defaultGateway = "203.0.113.2";
      my.services.nat64Warp = {
        enable = true;
        lanInterface = "eth1";
        tapInterface = "eth2";
        clients = [ "2001:db8:1::10/128" ];
        rio.enable = true;
      };
      systemd.services.nat64-host.wantedBy = [ "multi-user.target" ];
    };
    guest = {
      imports = [ (feature + /guest.nix) ];
      virtualisation.interfaces.eth1.vlan = 2;
      networking.interfaces.eth1 = {
        ipv4.addresses = [
          {
            address = "192.168.254.2";
            prefixLength = 30;
          }
        ];
        ipv6.addresses = [ (addr6 "fd64:35::2") ];
      };
      networking.defaultGateway = "192.168.254.1";
      my.services.nat64Guest = {
        enable = true;
        uplink = "eth1";
        clients = [ "2001:db8:1::10/128" ];
        warp = {
          enable = withWarp;
          interface = "warp-test";
          installClient = false;
        };
      };
      networking.firewall.allowedUDPPorts = [ 51820 ];
    };
    internet = {
      virtualisation.interfaces.eth1.vlan = 1;
      networking.interfaces.eth1 = {
        ipv4.addresses = [
          (addr4 "203.0.113.2")
          {
            address = "8.8.4.4";
            prefixLength = 32;
          }
        ];
        ipv6.addresses = [ (addr6 "2001:db8:1::2") ];
      };
      networking.firewall.allowedTCPPorts = [ 80 ];
      networking.firewall.allowedUDPPorts = [ 51820 ];
      services.nginx = {
        enable = true;
        virtualHosts.default.locations = {
          "/".extraConfig = "return 200 '$remote_addr';";
          "/large".root =
            pkgs.runCommand "large-http" { }
              "mkdir -p $out; head -c 100000 /dev/zero > $out/large";
        };
      };
    };
  };
  testScript = ''
    import json

    start_all()
    host.wait_for_unit("nat64-host.service")
    host.wait_for_unit("radvd.service")
    guest.wait_for_unit("tayga.service")
    internet.wait_for_unit("nginx.service")
    client.wait_until_succeeds("ip -6 route show | grep '64:ff9b:1:35::/96.*proto ra'")
    client.succeed("ip -6 route show default | grep '2001:db8:1::2'")
    assert len(client.succeed("ip -6 route show default").strip().splitlines()) == 1
    client.succeed("ip -6 route get 64:ff9b:1:35::808:404 | grep 'via fe80:'")
    client.succeed("ip -6 route get 2606:4700::1111 | grep 'via 2001:db8:1::2'")
    internet.succeed("curl -fsS --max-time 5 http://127.0.0.1")
    client.succeed("ping -c 1 -W 2 203.0.113.2")
    assert client.succeed("curl -fsS --max-time 5 http://8.8.4.4") == "203.0.113.10"
    ${lib.optionalString withWarp ''
      # Isolated WireGuard peer, not a connection to Cloudflare or a real account.
      for node in (guest, internet):
          node.succeed("umask 077; wg genkey > /var/lib/test-wg-key; wg pubkey < /var/lib/test-wg-key > /var/lib/test-wg-pub")
          node.succeed("ip link add warp-test type wireguard")
          node.succeed("ip link set warp-test mtu 1280")
      guest_pub = guest.succeed("cat /var/lib/test-wg-pub").strip()
      internet_pub = internet.succeed("cat /var/lib/test-wg-pub").strip()
      internet.succeed(f"wg set warp-test private-key /var/lib/test-wg-key listen-port 51820 peer {guest_pub} allowed-ips 198.18.0.1/32")
      internet.succeed("ip addr add 198.18.0.2/30 dev warp-test; ip link set warp-test up")
      guest.succeed(f"wg set warp-test private-key /var/lib/test-wg-key listen-port 51820 peer {internet_pub} allowed-ips 0.0.0.0/0 endpoint 203.0.113.2:51820 persistent-keepalive 1")
      guest.succeed("ip addr add 198.18.0.1/30 dev warp-test; ip link set warp-test up")
    ''}
    guest.succeed("tcpdump -ni ${
      if withWarp then "warp-test" else "eth1"
    } -c 1 -vv 'tcp[tcpflags] & tcp-syn != 0' > /tmp/mss.log 2>&1 &")
    guest.wait_until_succeeds("grep 'listening on' /tmp/mss.log")
    try:
        client.wait_until_succeeds("curl -g -6 -fsS --max-time 5 'http://[64:ff9b:1:35::808:404]'", timeout=40)
    except Exception:
        for node in (client, host, guest, internet):
            print(node.execute("ip addr; ip -6 route show table all; ip rule; ip -6 rule; nft list ruleset; journalctl -u tayga -u nat64-egress --no-pager"))
        raise
    source = client.succeed("curl -g -6 -fsS --max-time 5 'http://[64:ff9b:1:35::808:404]'")
    assert source == "${if withWarp then "198.18.0.1" else "203.0.113.1"}", source
    guest.wait_until_succeeds("grep 'mss 1220' /tmp/mss.log")
    client.succeed("ping -6 -c 2 -W 3 64:ff9b:1:35::808:404")
    status, output = client.execute("ping -6 -M do -s 1400 -c 2 -W 2 64:ff9b:1:35::808:404")
    assert status != 0, output
    client.succeed("ip -6 route get 64:ff9b:1:35::808:404 | grep 'mtu 1280'")
    internet.succeed("iptables -I INPUT -d 8.8.4.4 -p icmp --icmp-type echo-request -j REJECT --reject-with icmp-host-unreachable")
    status, output = client.execute("ping -6 -c 1 -W 3 64:ff9b:1:35::808:404")
    assert status != 0 and "unreachable" in output.lower(), output
    internet.succeed("iptables -D INPUT -d 8.8.4.4 -p icmp --icmp-type echo-request -j REJECT --reject-with icmp-host-unreachable")
    client.succeed("curl -g -6 -fsS --max-time 15 'http://[64:ff9b:1:35::808:404]/large' | wc -c | grep 100000")
    # Deny translating a private destination / alternate LAN or Tailnet access.
    client.fail("curl -g -6 -fsS --max-time 2 'http://[64:ff9b:1:35::c0a8:fe01]'")
    guest.succeed("nft list table inet nat64_guard | grep 'counter translated'")
    host.succeed("systemctl restart firewall")
    client.succeed("curl -g -6 -fsS --max-time 5 'http://[64:ff9b:1:35::808:404]'")
    ${lib.optionalString withWarp ''
      guest.succeed("ip link del warp-test")
      guest.wait_until_succeeds("ip route show table 1064 | grep unreachable")
      client.fail("curl -g -6 -fsS --max-time 3 'http://[64:ff9b:1:35::808:404]'")
      assert client.succeed("curl -fsS --max-time 5 http://8.8.4.4") == "203.0.113.10"
      guest.succeed("ip link add warp-test type wireguard; ip link set warp-test mtu 1280")
      guest.succeed(f"wg set warp-test private-key /var/lib/test-wg-key listen-port 51820 peer {internet_pub} allowed-ips 0.0.0.0/0 endpoint 203.0.113.2:51820 persistent-keepalive 1")
      guest.succeed("ip addr add 198.18.0.1/30 dev warp-test; ip link set warp-test up")
      client.wait_until_succeeds("curl -g -6 -fsS --max-time 5 'http://[64:ff9b:1:35::808:404]'")
      # A stopped route unit cannot expose the main table as a fallback.
      guest.succeed("systemctl stop nat64-egress")
      client.fail("ping -6 -c 1 -W 2 64:ff9b:1:35::808:404")
    ''}
    # Capture a real advertisement, including the header and its options.
    host.succeed("timeout 40 tcpdump -ni eth1 -c 1 -vv 'icmp6 && ip6[40] == 134' > /tmp/ra.log 2>&1")
    ra = host.succeed("cat /tmp/ra.log")
    assert "router lifetime 0s" in ra, ra
    assert "64:ff9b:1:35::/96" in ra, ra
    assert "prefix info option" not in ra and "rdnss" not in ra.lower(), ra
    host.succeed("systemctl stop radvd")
    client.wait_until_succeeds("test -z \"$(ip -6 route show 64:ff9b:1:35::/96)\"", timeout=100)
    client.succeed("ip -6 route show default | grep '2001:db8:1::2'")
    original = json.loads(host.succeed("cat /run/nat64-host/sysctls.json"))
    host.succeed("systemctl stop nat64-host")
    for path, value in original.items():
        assert host.succeed(f"cat {path}") == value
    host.fail("nft list table inet dotnix_nat64")
    host.fail("ip -6 rule show | grep 1064")
  '';
}
