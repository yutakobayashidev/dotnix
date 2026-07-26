{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  relayHostPort = 18788;
  domain = "tw.home.yutakobayashi.com";
  baseProfileDir = "/var/lib/twitter-api-safe-relay/chrome-profile";
  relayNetworkName = "twitter-api-safe-relay";
  tunnelServiceName = "tunnel-client-twitter-api-safe-relay";
  tunnelCredentialName = "control-plane-api-key";
  browserDebugPort = 9223;
  relayDebugPort = 9222;
  networkUnit = "twitter-api-safe-relay-network.service";
  chromeImage = "kasmweb/chrome:1.18.0@sha256:ae956514c4d034673423c46317a8c5994fe3517b34662155d467e6648571d195";
  socatImage = "alpine/socat:1.8.1.3@sha256:f134cb7ebb983f971f5deb44e92bc62c1385b0a3b525393f32dd0722acc30315";

  accountConfigs =
    lib.imap0
      (index: name: {
        inherit name;
        containerName = if index == 0 then "kasmweb" else "kasmweb-${name}";
        cdpContainerName = if index == 0 then "kasmweb-cdp" else "kasmweb-${name}-cdp";
        profileDir = "${baseProfileDir}/${name}";
        vncHostPort = 6901 + (index * 2);
        browserHostPort = 6900 + (index * 2);
        cdpHostPort = 9224 + index;
      })
      [
        "account1"
        "account2"
      ];

  mkAccountAttrs =
    getName: getValue:
    lib.listToAttrs (
      map (account: lib.nameValuePair (getName account) (getValue account)) accountConfigs
    );

  browserUnits = map (account: "podman-${account.containerName}.service") accountConfigs;
  cdpUnits = map (account: "podman-${account.cdpContainerName}.service") accountConfigs;
  relayDependencies = [ networkUnit ] ++ cdpUnits;

  browserContainers = mkAccountAttrs (account: account.containerName) (account: {
    image = chromeImage;
    ports = [
      "${toString account.browserHostPort}:3000"
      "${toString account.vncHostPort}:6901"
      "127.0.0.1:${toString account.cdpHostPort}:${toString relayDebugPort}"
    ];
    volumes = [
      "${account.profileDir}:/home/kasm-user/chrome-profile"
    ];
    environment = {
      VNC_PW = "password";
      APP_ARGS = lib.concatStringsSep " " [
        "--start-maximized"
        "--user-data-dir=/home/kasm-user/chrome-profile"
        "--password-store=basic"
        "--remote-debugging-port=${toString browserDebugPort}"
      ];
    };
    extraOptions = [
      "--shm-size=4g"
      "--network=${relayNetworkName}"
      "--network-alias=${account.containerName}"
    ];
  });

  cdpContainers = mkAccountAttrs (account: account.cdpContainerName) (account: {
    image = socatImage;
    cmd = [
      "TCP-LISTEN:${toString relayDebugPort},fork,reuseaddr"
      "TCP:127.0.0.1:${toString browserDebugPort}"
    ];
    extraOptions = [
      "--network=container:${account.containerName}"
    ];
  });

  browserServices = mkAccountAttrs (account: "podman-${account.containerName}") (account: {
    preStart = ''
      mkdir -p ${account.profileDir}
      rm -f ${account.profileDir}/SingletonLock ${account.profileDir}/SingletonSocket ${account.profileDir}/SingletonCookie ${account.profileDir}/DevToolsActivePort
      chown -R 1000:0 ${account.profileDir}
      chmod -R g+rwX ${account.profileDir}
    '';
    after = [
      "network-online.target"
      networkUnit
    ];
    requires = [ networkUnit ];
  });

  cdpServices = mkAccountAttrs (account: "podman-${account.cdpContainerName}") (account: {
    after = [
      networkUnit
      "podman-${account.containerName}.service"
    ];
    requires = [
      networkUnit
      "podman-${account.containerName}.service"
    ];
    partOf = [ "podman-${account.containerName}.service" ];
  });

in
{
  imports = [
    inputs.nur-packages.nixosModules.twitter-api-safe-mcp
    inputs.openai-secure-tunnel-nix.nixosModules.tunnel-client
  ];

  sops.secrets.openai-tunnel-api-key = {
    sopsFile = ../../../../secrets/openai-tunnel.yaml;
  };

  services = {
    twitter-api-safe-mcp = {
      enable = true;
      settings = {
        port = relayHostPort;
        profiles = map (account: {
          inherit (account) name;
          browser = {
            type = "cdp";
            browserType = "chromium";
            cdpEndpoint = "http://127.0.0.1:${toString account.cdpHostPort}";
          };
        }) accountConfigs;
      };
    };

    openai-tunnel-client.instances.twitter-api-safe-relay = {
      enable = true;
      settings = {
        config_version = 1;
        control_plane = {
          tunnel_id = "tunnel_6a605119f2bc8191b8aa9ffe352e095c";
          # The pinned Nix module turns apiKeyFile into an env reference whose
          # value is another file reference. tunnel-client resolves only one
          # reference layer, so point it at the systemd credential directly.
          api_key = "file:/run/credentials/${tunnelServiceName}.service/${tunnelCredentialName}";
        };
        health.listen_addr = "127.0.0.1:18789";
        admin_ui.open_browser = false;
        mcp.server_urls = [
          {
            channel = "main";
            url = "http://127.0.0.1:${toString relayHostPort}/mcp";
          }
        ];
      };
    };

    traefik.dynamicConfigOptions.http = {
      routers.twitter-api-safe-relay = {
        entryPoints = [
          "web"
          "websecure"
        ];
        rule = "Host(`${domain}`)";
        service = "twitter-api-safe-relay";
        tls.certResolver = "letsencrypt";
      };
      services.twitter-api-safe-relay.loadBalancer.servers = [
        { url = "http://127.0.0.1:${toString relayHostPort}"; }
      ];
    };
  };

  virtualisation.oci-containers.containers = browserContainers // cdpContainers;

  systemd = {
    services = {
      twitter-api-safe-relay-network = {
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        before = browserUnits ++ cdpUnits ++ [ "twitter-api-safe-mcp.service" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if ! ${lib.getExe pkgs.podman} network inspect ${relayNetworkName} >/dev/null 2>&1; then
            ${lib.getExe pkgs.podman} network create ${relayNetworkName}
          fi
        '';
      };
    }
    // browserServices
    // cdpServices
    // {
      tunnel-client-twitter-api-safe-relay = {
        after = [ "twitter-api-safe-mcp.service" ];
        wants = [ "twitter-api-safe-mcp.service" ];
        serviceConfig.LoadCredential = [
          "${tunnelCredentialName}:${config.sops.secrets.openai-tunnel-api-key.path}"
        ];
      };
      twitter-api-safe-mcp = {
        after = relayDependencies;
        requires = relayDependencies;
      };
    };
    tmpfiles.rules = builtins.map (account: "d ${account.profileDir} 0755 1000 0 - -") accountConfigs;
  };
}
