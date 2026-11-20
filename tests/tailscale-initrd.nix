# Boots a LUKS-encrypted VM whose systemd initrd joins a local headscale
# tailnet, then unlocks it over SSH from another tailnet peer.
{
  nixpkgs,
  inputs,
}:

let
  pkgs = import nixpkgs { system = "x86_64-linux"; };
  inherit (pkgs) lib;

  tailscaleModule =
    (import ../modules/features/network/tailscale.nix { }).flake.modules.nixos.tailscale;

  passphrase = "supersecret";

  tlsCert = pkgs.runCommand "headscale-test-cert" { nativeBuildInputs = [ pkgs.openssl ]; } ''
    openssl req -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
      -out cert.pem -keyout key.pem \
      -subj '/CN=headscale' -addext 'subjectAltName=DNS:headscale'
    mkdir -p $out
    cp cert.pem key.pem $out
  '';

  # Test-only client key; never used outside this VM test.
  clientKey = pkgs.runCommand "initrd-unlock-test-key" { nativeBuildInputs = [ pkgs.openssh ]; } ''
    mkdir -p $out
    ssh-keygen -q -t ed25519 -N "" -C initrd-unlock-test -f $out/id_ed25519
  '';

  unlockScript = pkgs.writeScript "unlock-over-tailnet" ''
    #!${pkgs.expect}/bin/expect -f
    set timeout 120
    set target [lindex $argv 0]
    spawn ${pkgs.openssh}/bin/ssh -tt -i /etc/initrd-unlock-key \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      root@$target systemd-tty-ask-password-agent
    expect {
      -re "(?i)passphrase" { send "${passphrase}\r" }
      timeout { exit 1 }
    }
    expect eof
  '';
in
pkgs.testers.runNixOSTest {
  name = "tailscale-initrd";

  node.specialArgs = { inherit inputs; };

  nodes = {
    headscale = {
      services = {
        headscale = {
          enable = true;
          port = 8080;
          settings = {
            server_url = "https://headscale";
            prefixes.v4 = "100.64.0.0/10";
            derp = {
              server = {
                enabled = true;
                region_id = 999;
                stun_listen_addr = "0.0.0.0:3478";
              };
              urls = [ ];
            };
            dns = {
              magic_dns = false;
              override_local_dns = false;
            };
          };
        };
        nginx = {
          enable = true;
          virtualHosts.headscale = {
            addSSL = true;
            sslCertificate = "${tlsCert}/cert.pem";
            sslCertificateKey = "${tlsCert}/key.pem";
            locations."/" = {
              proxyPass = "http://127.0.0.1:8080";
              proxyWebsockets = true;
            };
          };
        };
      };
      networking.firewall = {
        allowedTCPPorts = [
          80
          443
        ];
        allowedUDPPorts = [ 3478 ];
      };
      environment.systemPackages = [ pkgs.headscale ];
    };

    client = {
      services.tailscale.enable = true;
      security.pki.certificateFiles = [ "${tlsCert}/cert.pem" ];
      environment.etc."initrd-unlock-key" = {
        source = "${clientKey}/id_ed25519";
        mode = "0600";
      };
    };

    machine =
      { nodes, ... }:
      {
        imports = [ tailscaleModule ];

        virtualisation = {
          emptyDiskImages = [ 512 ];
          useBootLoader = true;
          useEFIBoot = true;
          # Booting off the encrypted disk requires an available init script.
          mountHostNixStore = true;
        };
        boot.loader.systemd-boot.enable = true;
        networking.useNetworkd = true;
        security.pki.certificateFiles = [ "${tlsCert}/cert.pem" ];
        environment.systemPackages = [ pkgs.cryptsetup ];

        specialisation.boot-luks.configuration = {
          boot.initrd.luks.devices = lib.mkVMOverride {
            cryptroot.device = "/dev/vdb";
          };
          virtualisation.rootDevice = "/dev/mapper/cryptroot";

          my.services.tailscale.initrd = {
            enable = true;
            kernelModules = [ "virtio_net" ];
            authorizedKeys = [ (builtins.readFile "${clientKey}/id_ed25519.pub") ];
            authKeyFile = "/etc/initrd-tailscale-authkey";
            sshHostKey = "/etc/initrd_ssh_host_ed25519_key";
            extraUpFlags = [ "--login-server=https://headscale" ];
          };
          boot.initrd.systemd.contents."/etc/hosts".text = ''
            ${nodes.headscale.networking.primaryIPAddress} headscale
          '';
        };
      };
  };

  testScript =
    { nodes, ... }:
    let
      bootLuks = nodes.machine.specialisation.boot-luks.configuration.system.build.toplevel;
    in
    ''
      from datetime import timedelta

      start_all()

      headscale.wait_for_unit("headscale.service")
      headscale.wait_for_open_port(443)
      headscale.succeed("headscale users create test")
      user_id = headscale.succeed(
          "headscale users list -o json | ${pkgs.jq}/bin/jq -r '.[] | select(.name == \"test\") | .id'"
      ).strip()
      authkey = headscale.succeed(
          f"headscale preauthkeys create -u {user_id} --reusable --ephemeral"
      ).strip().splitlines()[-1]

      client.wait_for_unit("tailscaled.service")
      client.succeed(f"tailscale up --login-server=https://headscale --auth-key={authkey}")

      with subtest("prepare the encrypted root and stage 1 secrets"):
          machine.wait_for_unit("multi-user.target")
          machine.succeed("echo -n ${passphrase} | cryptsetup luksFormat -q --iter-time=1 /dev/vdb -")
          machine.succeed("echo -n ${passphrase} | cryptsetup luksOpen -q /dev/vdb cryptroot")
          machine.succeed("mkfs.ext4 -q /dev/mapper/cryptroot")
          machine.succeed(f"printf '%s' '{authkey}' > /etc/initrd-tailscale-authkey")
          machine.succeed("chmod 600 /etc/initrd-tailscale-authkey")
          machine.succeed("ssh-keygen -q -t ed25519 -N ''' -f /etc/initrd_ssh_host_ed25519_key")
          machine.succeed("${bootLuks}/bin/switch-to-configuration boot")
          machine.succeed("sync")
          machine.crash()

      with subtest("stage 1 joins the tailnet and waits for the passphrase"):
          machine.start()
          machine.wait_for_console_text("Please enter passphrase for disk cryptroot")
          client.wait_until_succeeds("tailscale ip -4 machine-initrd", timeout=timedelta(seconds=180))
          headscale.succeed("headscale nodes list | grep -q machine-initrd")

      with subtest("unlock over the tailnet"):
          ip = client.succeed("tailscale ip -4 machine-initrd").strip()
          client.wait_until_succeeds(f"${pkgs.netcat}/bin/nc -z {ip} 22", timeout=timedelta(seconds=120))
          client.succeed(f"${unlockScript} {ip}")
          machine.wait_for_unit("multi-user.target")
          machine.succeed("mount | grep -q '/dev/mapper/cryptroot on / type ext4'")

      with subtest("the ephemeral stage 1 node leaves the tailnet"):
          headscale.wait_until_fails("headscale nodes list | grep -q machine-initrd", timeout=timedelta(seconds=60))
    '';
}
