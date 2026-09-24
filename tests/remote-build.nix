{
  nixpkgs ? <nixpkgs>,
}:

let
  pkgs = import nixpkgs { system = "x86_64-linux"; };
  remoteBuild = (import ../modules/features/remote-build.nix { }).flake.modules.nixos.remote-build;
in
pkgs.testers.runNixOSTest {
  name = "remote-build";

  defaults = { lib, ... }: {
    imports = [ remoteBuild ];
    # Model only the secret path contract. No production SOPS file is read.
    options.sops.secrets = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          freeformType = lib.types.attrsOf lib.types.anything;
          options.path = lib.mkOption { type = lib.types.str; };
        }
      );
    };
    config = {
      _module.args.self.nixosConfigurations.UM790-Pro.config.nix.settings.system-features = [ ];
      nix.settings.experimental-features = [ "nix-command" ];
      nix.settings.substituters = lib.mkForce [ ];
      environment.systemPackages = [ pkgs.bash ];
    };
  };

  nodes = {
    builder = { lib, ... }: {
      my.nix.remoteBuild.builder.enable = true;
      nix.sshServe.keys = lib.mkForce [ ];
      networking.dhcpcd.denyInterfaces = [ "tailscale0" ];
    };

    client = { lib, nodes, ... }: {
      config = {
        my.nix.remoteBuild.client.enable = true;
        sops.secrets.remote-build-key.path = "/root/.ssh/remote-build";
        programs.ssh.knownHosts = lib.mkForce { };
        networking.hosts.${nodes.builder.networking.primaryIPAddress} = [
          "um790-pro.tail29d068.ts.net"
        ];
        environment.etc."remote-build-test.nix".text = ''
          { name }:
          builtins.derivation {
            inherit name;
            system = "x86_64-linux";
            builder = builtins.storePath "${pkgs.bash}" + "/bin/bash";
            args = [ "-c" "echo success > $out" ];
          }
        '';
      };
    };
  };

  testScript = ''
    import shlex

    start_all()
    builder.wait_for_unit("sshd.service")
    client.wait_for_unit("nix-daemon.socket")

    # Private keys are generated and retained only inside this throwaway VM.
    client.succeed("install -d -m 700 /root/.ssh")
    client.succeed("ssh-keygen -q -t ed25519 -N \"\" -f /root/.ssh/remote-build")
    public_key = client.succeed("cat /root/.ssh/remote-build.pub").strip()
    client_ip = client.succeed("ip -4 -o address show eth1").split()[3].split("/")[0]
    builder.succeed("install -d -m 755 /etc/ssh/authorized_keys.d")
    builder.succeed("printf '%s\\n' " + shlex.quote('from="' + client_ip + '" ' + public_key) + " > /etc/ssh/authorized_keys.d/nix-ssh")
    host_key = builder.succeed("cat /etc/ssh/ssh_host_ed25519_key.pub").strip()
    client.succeed("printf '%s\\n' " + shlex.quote("[builder]:2223,[um790-pro.tail29d068.ts.net]:2223 " + host_key) + " > /root/.ssh/known_hosts")

    with subtest("build port is closed outside the Tailnet interface"):
        client.fail("nix store info --store ssh-ng://nix-ssh@um790-builder")

    # The isolated test network stands in for the real Tailscale interface.
    builder.succeed("ip link set eth1 down; ip link set eth1 name tailscale0; ip link set tailscale0 up")
    with subtest("forced daemon connection and actual remote build"):
        client.wait_until_succeeds("nix store info --store ssh-ng://nix-ssh@um790-builder")
        client.fail("nix-build /etc/remote-build-test.nix --argstr name remote-proof --builders \"\" --no-out-link")
        client.succeed("nix-build /etc/remote-build-test.nix --argstr name remote-proof --no-out-link > /root/result 2> /root/build.log")
        assert "on 'ssh-ng://nix-ssh@um790-builder'" in client.succeed("cat /root/build.log")
        client.succeed('test "$(cat $(cat /root/result))" = success')
        result = client.succeed("cat /root/result").strip()
        builder.succeed("nix-store --check-validity " + shlex.quote(result))
        builder.succeed("test \"$(cat " + shlex.quote(result) + ")\" = success")

    with subtest("unknown client key is rejected"):
        client.succeed("ssh-keygen -q -t ed25519 -N \"\" -f /root/.ssh/unauthorized")
        status, output = client.execute("ssh -4 -F /dev/null -o ConnectTimeout=2 -o BatchMode=yes -o StrictHostKeyChecking=yes -o IdentitiesOnly=yes -i /root/.ssh/unauthorized -p 2223 nix-ssh@builder true 2>&1")
        assert status != 0 and "Permission denied" in output, output

    with subtest("offline builder fails and explicit local override works"):
        builder.succeed("systemctl stop sshd.service")
        status, output = client.execute("timeout 30 nix-build /etc/remote-build-test.nix --argstr name unavailable-proof --no-out-link 2>&1")
        assert status not in (0, 124), output
        client.succeed("nix-build /etc/remote-build-test.nix --argstr name local-proof --builders \"\" --max-jobs 1 --no-out-link")
  '';
}
