_:

{
  flake.modules.nixos."tailscale" =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.my.services.tailscale;
      initrdCfg = cfg.initrd;
      tailscale = config.services.tailscale.package;
      initrdAuthKeyPath = "/etc/tailscale/authkey";
    in
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      options.my.services.tailscale = {
        enable = lib.mkEnableOption "Tailscale VPN";

        configureResolver = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable systemd-resolved for Tailscale DNS (desktop systems).";
        };

        initrd = {
          enable = lib.mkEnableOption ''
            Tailscale and SSH in systemd stage 1 for remote LUKS unlocking.
            Connect with `ssh root@<hostname>` over the tailnet and run
            `systemd-tty-ask-password-agent`'';

          hostname = lib.mkOption {
            type = lib.types.str;
            default = "${config.networking.hostName}-initrd";
            defaultText = lib.literalExpression ''"''${config.networking.hostName}-initrd"'';
            description = "Tailnet node name used in stage 1; must differ from the main node.";
          };

          authKeyFile = lib.mkOption {
            type = lib.types.str;
            default = "/persist/etc/secrets/initrd/tailscale-authkey";
            description = ''
              Host path to a reusable, ephemeral, pre-approved, tagged auth key.
              It is embedded unencrypted in the initrd via `boot.initrd.secrets`,
              so it cannot be managed by sops-nix.
            '';
          };

          sshHostKey = lib.mkOption {
            type = lib.types.str;
            default = "/persist/etc/ssh/initrd_ssh_host_ed25519_key";
            description = "Dedicated stage 1 SSH host key; do not reuse the main host key.";
          };

          authorizedKeys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Public keys allowed to log in as root in stage 1.";
          };

          kernelModules = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "r8169" ];
            description = "Wired NIC drivers needed in stage 1.";
          };
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            services.tailscale = {
              enable = true;
              useRoutingFeatures = "server";
              authKeyFile = config.sops.secrets.tailscale-authkey.path;
              extraUpFlags = [ "--ssh" ];
              extraSetFlags = [
                "--accept-dns=${lib.boolToString cfg.configureResolver}"
              ];
            };

            networking = {
              firewall = {
                trustedInterfaces = [ "tailscale0" ];
                allowedUDPPorts = [ config.services.tailscale.port ];
              };
            };

            sops.secrets.tailscale-authkey = { };
          }
          (lib.mkIf cfg.configureResolver {
            services.resolved.enable = true;
          })
          (lib.mkIf initrdCfg.enable {
            assertions = [
              {
                assertion = config.boot.initrd.systemd.enable;
                message = "my.services.tailscale.initrd requires boot.initrd.systemd.enable.";
              }
              {
                assertion = initrdCfg.authorizedKeys != [ ];
                message = "my.services.tailscale.initrd.authorizedKeys must not be empty.";
              }
              {
                assertion = initrdCfg.kernelModules != [ ];
                message = "my.services.tailscale.initrd.kernelModules must list the wired NIC driver.";
              }
            ];

            boot.initrd = {
              availableKernelModules = initrdCfg.kernelModules;
              kernelModules = [ "tun" ];

              network = {
                enable = true;
                flushBeforeStage2 = true;
                ssh = {
                  enable = true;
                  port = 22;
                  hostKeys = [ initrdCfg.sshHostKey ];
                  inherit (initrdCfg) authorizedKeys;
                };
              };

              secrets.${initrdAuthKeyPath} = initrdCfg.authKeyFile;

              systemd = {
                network = {
                  enable = true;
                  networks."10-initrd-wired" = {
                    matchConfig.Type = "ether";
                    networkConfig.DHCP = "yes";
                  };
                };

                initrdBin = [ tailscale ];
                contents."/etc/ssl/certs/ca-certificates.crt".source = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

                services = {
                  tailscaled = {
                    description = "Tailscale node agent (stage 1)";
                    wantedBy = [ "initrd.target" ];
                    after = [ "systemd-networkd.service" ];
                    wants = [ "systemd-networkd.service" ];
                    before = [ "shutdown.target" ];
                    conflicts = [ "shutdown.target" ];
                    unitConfig.DefaultDependencies = false;
                    serviceConfig = {
                      ExecStart = "${tailscale}/bin/tailscaled --state=mem: --no-logs-no-support --tun=tailscale0";
                      Restart = "on-failure";
                      RuntimeDirectory = "tailscale";
                    };
                  };

                  tailscale-up = {
                    description = "Join the tailnet (stage 1)";
                    wantedBy = [ "initrd.target" ];
                    after = [
                      "tailscaled.service"
                      "initrd-nixos-copy-secrets.service"
                    ];
                    requires = [ "tailscaled.service" ];
                    before = [ "shutdown.target" ];
                    conflicts = [ "shutdown.target" ];
                    unitConfig.DefaultDependencies = false;
                    serviceConfig = {
                      Type = "oneshot";
                      RemainAfterExit = true;
                      ExecStart = lib.concatStringsSep " " [
                        "${tailscale}/bin/tailscale up"
                        "--auth-key=file:${initrdAuthKeyPath}"
                        "--hostname=${initrdCfg.hostname}"
                        "--accept-dns=false"
                        "--netfilter-mode=off"
                        "--timeout=300s"
                      ];
                      # Remove the ephemeral node before switching root.
                      ExecStop = "-${tailscale}/bin/tailscale logout";
                    };
                  };
                };
              };
            };
          })
        ]
      );
    };
}
