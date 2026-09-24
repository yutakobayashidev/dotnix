_:

{
  flake.modules.nixos.remote-build =
    {
      config,
      lib,
      self,
      ...
    }:
    let
      cfg = config.my.nix.remoteBuild;
      builder = self.nixosConfigurations.UM790-Pro.config;
      builderHost = "um790-pro.tail29d068.ts.net";
      builderPort = 2223;
    in
    {
      options.my.nix.remoteBuild = {
        client.enable = lib.mkEnableOption "offloading Nix builds to UM790-Pro";
        builder.enable = lib.mkEnableOption "accepting Nix builds on UM790-Pro";
      };

      config = lib.mkMerge [
        {
          assertions = [
            {
              assertion = !(cfg.client.enable && cfg.builder.enable);
              message = "A remote-build host cannot be both a client and a builder.";
            }
          ];
        }

        (lib.mkIf cfg.client.enable {
          sops.secrets.remote-build-key = {
            sopsFile = ../../secrets + "/remote-build-${config.networking.hostName}.yaml";
            owner = "root";
            mode = "0400";
          };

          nix = {
            distributedBuilds = true;
            settings = {
              max-jobs = 0;
              builders-use-substitutes = true;
            };
            buildMachines = [
              {
                hostName = "um790-builder";
                protocol = "ssh-ng";
                sshUser = "nix-ssh";
                sshKey = config.sops.secrets.remote-build-key.path;
                systems = [ "x86_64-linux" ];
                # Each client has its own scheduler; leave room for the other client.
                maxJobs = 2;
                supportedFeatures = builder.nix.settings.system-features;
              }
            ];
          };

          programs.ssh = {
            knownHosts.um790-builder = {
              hostNames = [ "[${builderHost}]:${toString builderPort}" ];
              publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIef61G9oFD/d/ahrH9jrbt7TIYn4atwnKXpP1BWHtr";
            };
            extraConfig = ''
              Host um790-builder
                HostName ${builderHost}
                AddressFamily inet
                Port ${toString builderPort}
                User nix-ssh
                IdentityFile ${config.sops.secrets.remote-build-key.path}
                IdentitiesOnly yes
                BatchMode yes
                StrictHostKeyChecking yes
                ConnectTimeout 5
                ServerAliveInterval 15
                ServerAliveCountMax 3
            '';
          };
        })

        (lib.mkIf cfg.builder.enable {
          nix = {
            distributedBuilds = false;
            settings.allowed-users = [ "nix-ssh" ];
            sshServe = {
              enable = true;
              protocol = "ssh-ng";
              trusted = true;
              keys = [
                ''from="100.111.109.43" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdj/CaRWv/u1HtyfSWOtuOpBtJ/d2StcpH3JD1FxSMC remote-build:B450M-Pro4''
                ''from="100.97.60.85" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILwJcMp+VVq/bGYowhV3ePyqGekT+ir1wAFd61JqLrqj remote-build:ThinkPad-X1-Carbon-Gen13''
              ];
            };
          };

          services.openssh = {
            ports = [
              22
              builderPort
            ];
            # Tailscale SSH owns port 22 on the tailnet; use ordinary sshd on 2223.
            openFirewall = false;
          };
          networking.firewall = {
            allowedTCPPorts = [ 22 ];
            interfaces.tailscale0.allowedTCPPorts = [ builderPort ];
          };
        })
      ];
    };
}
