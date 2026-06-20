{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.microvm.nixosModules.host
  ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking = {
    networkmanager.unmanaged = [
      "interface-name:microbr-oc"
      "interface-name:microvm-oc"
    ];
    firewall.interfaces.microbr-oc.allowedUDPPorts = [ 53 ];
    nftables = {
      enable = true;
      tables."openclaw-microvm" = {
        family = "inet";
        content = ''
          chain forward {
            type filter hook forward priority 10; policy accept;
            iifname "microbr-oc" ct state new log prefix "openclaw-egress: " accept
          }

          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            oifname != "microbr-oc" ip saddr 192.168.84.0/24 masquerade
          }
        '';
      };
    };
  };

  services.coredns = {
    enable = true;
    config = ''
      .:53 {
        bind 192.168.84.1
        forward . 1.1.1.1 8.8.8.8
        log
        errors
      }
    '';
  };

  security = {
    auditd.enable = true;
    audit = {
      enable = true;
      rules = [
        "-w /var/lib/microvms/openclaw/secrets/ -p rwa -k openclaw-secrets"
      ];
    };
  };

  microvm.autostart = [ "openclaw" ];

  microvm.vms.openclaw = {
    specialArgs = {
      openclawHmModule = inputs.nix-openclaw.homeManagerModules.openclaw;
    };

    config = {
      imports = [
        ./guest.nix
        inputs.home-manager.nixosModules.home-manager
      ];

      nixpkgs.overlays = [
        inputs.nix-openclaw.overlays.default
      ];
    };
  };

  systemd = {
    network = {
      enable = true;
      netdevs."20-microbr-oc".netdevConfig = {
        Kind = "bridge";
        Name = "microbr-oc";
      };
      networks = {
        "20-microbr-oc" = {
          matchConfig.Name = "microbr-oc";
          addresses = [
            { Address = "192.168.84.1/24"; }
          ];
          networkConfig.ConfigureWithoutCarrier = true;
        };
        "21-microvm-openclaw" = {
          matchConfig.Name = "microvm-oc";
          networkConfig.Bridge = "microbr-oc";
        };
      };
    };
    services = {
      "microvm@openclaw".serviceConfig.TimeoutStartSec = "300";
      openclaw-prepare-secrets = {
        description = "Stage secrets for OpenClaw microVM";
        wantedBy = [ "microvm@openclaw.service" ];
        before = [ "microvm@openclaw.service" ];
        serviceConfig.Type = "oneshot";

        script = ''
          set -eu

          dir=/var/lib/microvms/openclaw/secrets
          install -d -m 0755 "$dir"

          if [ ! -s "$dir/gateway-token" ]; then
            ${pkgs.openssl}/bin/openssl rand -base64 32 > "$dir/gateway-token"
          fi

          : > "$dir/gateway-env"

          add_secret_env() {
            name="$1"
            file="$2"
            if [ -s "$dir/$file" ]; then
              printf '%s=%s\n' "$name" "$(cat "$dir/$file")" >> "$dir/gateway-env"
            fi
          }

          add_secret_env OPENAI_API_KEY openai-api-key
          add_secret_env ANTHROPIC_API_KEY anthropic-api-key
          add_secret_env OPENROUTER_API_KEY openrouter-api-key
          add_secret_env DISCORD_BOT_TOKEN discord-bot-token
          add_secret_env TELEGRAM_BOT_TOKEN telegram-bot-token

          chmod 0444 "$dir/gateway-token" "$dir/gateway-env"
        '';
      };
    };
  };
}
