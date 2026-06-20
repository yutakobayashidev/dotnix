{
  openclawHmModule,
  pkgs,
  ...
}:

{
  networking = {
    hostName = "openclaw-vm";
    enableIPv6 = false;
    nameservers = [ "192.168.84.1" ];
  };

  microvm = {
    vcpu = 4;
    mem = 4096;

    interfaces = [
      {
        type = "tap";
        id = "microvm-oc";
        mac = "02:00:00:00:4f:01";
      }
    ];

    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
      {
        source = "/var/lib/microvms/openclaw/secrets";
        mountPoint = "/run/secrets";
        tag = "secrets";
        proto = "virtiofs";
      }
    ];

    writableStoreOverlay = "/nix/.rw-store";

    volumes = [
      {
        image = "state.img";
        mountPoint = "/persist";
        size = 8192;
        label = "openclaw-state";
      }
    ];
  };

  users.users.openclaw = {
    isNormalUser = true;
    home = "/persist/openclaw";
    createHome = true;
    group = "openclaw";
    linger = true;
  };
  users.groups.openclaw = { };

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
  };

  systemd = {
    network = {
      enable = true;
      networks."10-eth" = {
        matchConfig.Name = "e*";
        addresses = [
          { Address = "192.168.84.2/24"; }
        ];
        routes = [
          { Gateway = "192.168.84.1"; }
        ];
      };
    };
    tmpfiles.rules = [
      "d /persist/openclaw 0755 openclaw openclaw -"
      "d /persist/openclaw/.config/systemd/user/default.target.wants 0755 openclaw openclaw -"
      "L /persist/openclaw/.config/systemd/user/default.target.wants/openclaw-gateway.service - openclaw openclaw - /persist/openclaw/.config/systemd/user/openclaw-gateway.service"
      "d /tmp/openclaw 0755 openclaw openclaw -"
      "r /persist/openclaw/.openclaw/*.bak* - - - - -"
      "r /persist/openclaw/.openclaw/workspace/*.bak* - - - - -"
    ];
    services = {
      home-manager-openclaw.environment.HOME_MANAGER_BACKUP_OVERWRITE = "1";
      openclaw-pre-hm-cleanup = {
        description = "Remove regular files that Home Manager manages as symlinks";
        wantedBy = [ "home-manager-openclaw.service" ];
        before = [ "home-manager-openclaw.service" ];
        serviceConfig.Type = "oneshot";

        script = ''
          for f in \
            /persist/openclaw/.openclaw/openclaw.json \
            /persist/openclaw/.openclaw/workspace/AGENTS.md \
            /persist/openclaw/.openclaw/workspace/SOUL.md \
            /persist/openclaw/.openclaw/workspace/TOOLS.md; do
            [ -f "$f" ] && [ ! -L "$f" ] && rm -f "$f"
          done

          rm -f /persist/openclaw/.openclaw/*.bak* /persist/openclaw/.openclaw/workspace/*.bak*
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    curl
    jq
    ripgrep
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    users.openclaw = {
      imports = [
        openclawHmModule
      ];

      home = {
        username = "openclaw";
        homeDirectory = "/persist/openclaw";
        stateVersion = "25.11";
      };

      systemd.user.services.openclaw-gateway.Service = {
        EnvironmentFile = "-/run/secrets/gateway-env";
        Environment = [
          "PATH=/run/current-system/sw/bin:/run/wrappers/bin:/persist/openclaw/.nix-profile/bin"
        ];
      };

      programs.openclaw = {
        documents = ./documents;

        bundledPlugins = {
          summarize.enable = true;
          gogcli.enable = true;
        };

        instances.default = {
          enable = true;
          systemd.enable = true;

          config = {
            gateway = {
              mode = "local";
              bind = "loopback";
              auth = {
                mode = "token";
                token = "/run/secrets/gateway-token";
              };
              reload.mode = "hybrid";
            };

            agents.defaults = {
              model.primary = "openai-codex/gpt-5.3-codex";
              sandbox.mode = "off";
            };

            discovery.mdns.mode = "minimal";
            tools.deny = [
              "gateway"
              "cron"
              "elevated"
            ];
          };
        };
      };
    };
  };

  services.journald.extraConfig = ''
    ForwardToConsole=yes
    MaxLevelConsole=info
  '';

  system.stateVersion = "25.11";
}
