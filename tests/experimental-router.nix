{
  nixpkgs ? <nixpkgs>,
}:
let
  pkgs = import nixpkgs { system = "x86_64-linux"; };
in
pkgs.testers.runNixOSTest {
  name = "experimental-router";
  nodes = {
    router = { lib, ... }: {
      imports = [ ../modules/features/network/experimental-router/module.nix ];
      virtualisation.vlans = [
        1
        2
      ];
      networking = {
        interfaces = {
          eth2.ipv4.addresses = lib.mkForce [ ];
          eth1.ipv4.addresses = [
            {
              address = "192.168.50.2";
              prefixLength = 24;
            }
          ];
        };
        useDHCP = false;
        defaultGateway = "192.168.50.1";
      };
      my.services.experimentalRouter = {
        enable = true;
        wanInterface = "eth1";
        lanInterface = "eth2";
        upstreamDNS = "192.168.50.1";
      };
      # Exercise coexistence with Docker's FORWARD policy/chains.
      virtualisation.docker.enable = true;
      environment.systemPackages = [
        pkgs.nftables
        pkgs.dig
      ];
    };
    wan = _: {
      virtualisation.vlans = [ 1 ];
      networking = {
        useDHCP = false;
        firewall.enable = false;
        interfaces.eth1 = {
          ipv4 = {
            addresses = [
              {
                address = "192.168.50.1";
                prefixLength = 24;
              }
              {
                address = "198.18.0.1";
                prefixLength = 24;
              }
            ];
            routes = [
              {
                address = "10.77.10.0";
                prefixLength = 24;
                via = "192.168.50.2";
              }
            ];
          };
          ipv6.addresses = [
            {
              address = "fd00:1::1";
              prefixLength = 64;
            }
          ];
        };
      };
      services.dnsmasq = {
        enable = true;
        settings.address = "/router-test.example/198.18.0.1";
      };
      services.nginx = {
        enable = true;
        virtualHosts.default.locations."/".return = "200 ok";
      };
      environment.systemPackages = [ pkgs.tcpdump ];
    };
    client = { lib, ... }: {
      virtualisation.vlans = [ 2 ];
      networking = {
        useDHCP = false;
        interfaces.eth1 = {
          useDHCP = true;
          ipv4.addresses = lib.mkForce [ ];
        };
        firewall.enable = false;
      };
      environment.systemPackages = [ pkgs.dig ];
    };
  };
  testScript = ''
    import re

    start_all()
    router.wait_for_unit("experimental-router-firewall.service")
    router.wait_for_unit("docker.service")
    wan.wait_for_unit("nginx.service")
    client.wait_until_succeeds("ip -4 addr show eth1 | grep '10.77.10.'")
    client.succeed("ip route | grep 'default via 10.77.10.1'")
    client.wait_until_succeeds("curl --fail --max-time 5 http://198.18.0.1")
    # The upstream sees the router's WAN address, not the client's address.
    wan.succeed("tcpdump -ni eth1 -c 1 'src host 192.168.50.2 and dst host 198.18.0.1 and tcp port 80' > /tmp/nat.txt 2>&1 &")
    wan.wait_until_succeeds("grep 'listening on' /tmp/nat.txt")
    client.succeed("curl --fail --max-time 5 http://198.18.0.1")
    wan.wait_until_succeeds("grep '192.168.50.2' /tmp/nat.txt")
    client.succeed("dig @10.77.10.1 router-test.example +short | grep 198.18.0.1")
    client.fail("curl --fail --max-time 2 http://192.168.50.1")
    client.fail("curl --fail --max-time 2 http://192.168.50.2:22")
    address = client.succeed("ip -4 -o addr show eth1 | awk '{print $4}' | cut -d/ -f1").strip()
    wan.fail(f"ping -c 1 -W 2 {address}")
    # Force IPv6 on both sides to prove the firewall, not just lack of RA.
    router.succeed("ip -6 addr add fd00:1::2/64 dev eth1 nodad; ip -6 addr add fd00:2::1/64 dev eth2 nodad; sysctl -w net.ipv6.conf.all.forwarding=1")
    client.succeed("ip -6 addr add fd00:2::2/64 dev eth1 nodad; ip -6 route add default via fd00:2::1")
    wan.succeed("ip -6 route add fd00:2::/64 via fd00:1::2")
    router_mac = router.succeed("cat /sys/class/net/eth2/address").strip()
    client.succeed(f"ip -6 neigh replace fd00:2::1 lladdr {router_mac} nud permanent dev eth1")
    def drops():
        match = re.search(r"packets (\d+)", router.succeed("nft list counter inet dotnix_experimental_router forward_drop"))
        assert match is not None
        return int(match.group(1))
    before = drops()
    client.fail("ping -6 -c 1 -W 2 fd00:1::1")
    assert drops() > before, "IPv6 must reach and be rejected by the forwarding guard"
    router.succeed("nft -c -f /etc/experimental-router.nft")
    router.succeed("systemctl reload experimental-router-firewall")
    client.succeed("curl --fail --max-time 5 http://198.18.0.1")
    router.succeed("systemctl restart docker.service; systemctl reload firewall.service")
    client.succeed("curl --fail --max-time 5 http://198.18.0.1")
    client.fail("curl --fail --max-time 2 http://192.168.50.1")
    # An overlapping route prevents starting; no production routes are touched.
    router.succeed("ip route add 10.77.10.0/25 via 192.168.50.1 dev eth1")
    router.fail("${pkgs.python3}/bin/python3 ${../modules/features/network/experimental-router/preflight.py} eth2 eth1 10.77.10.0/24")
    router.succeed("systemctl stop experimental-router-firewall")
    router.succeed("ip -j link show eth2 | grep -v '\"UP\"'")
  '';
}
