{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  relayHostPort = 18788;
  package = pkgs.twitter-api-safe-mcp;
  domain = "tw.home.yutakobayashi.com";
  outputDir = "/var/lib/immich-net-pics";
  baseProfileDir = "/var/lib/twitter-api-safe-relay/chrome-profile";
  relayNetworkName = "twitter-api-safe-relay";
  tunnelServiceName = "tunnel-client-twitter-api-safe-relay";
  tunnelCredentialName = "control-plane-api-key";
  browserDebugPort = 9223;
  relayDebugPort = 9222;
  accounts = [
    "account1"
    "account2"
  ];

  accountConfigs = lib.imap0 (index: name: {
    inherit name;
    containerName = if index == 0 then "kasmweb" else "kasmweb-${name}";
    cdpContainerName = if index == 0 then "kasmweb-cdp" else "kasmweb-${name}-cdp";
    profileDir = "${baseProfileDir}/${name}";
    vncHostPort = 6901 + (index * 2);
    browserHostPort = 6900 + (index * 2);
  }) accounts;

  bookmark-snap = pkgs.buildNpmPackage {
    pname = "twitter-bookmark-snap";
    version = "0.0.1";
    src = ./bookmark-snap;
    npmDepsHash = "sha256-H2WmmgdWRdVx6fOrTjDtXB8btkAxSsj/pTIu0N66JfQ=";
    PUPPETEER_SKIP_DOWNLOAD = true;
    dontNpmBuild = true;

    buildPhase = ''
      ${lib.getExe pkgs.nodejs} node_modules/typescript/bin/tsc
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp -r dist $out/lib/
      cp -r node_modules $out/lib/
    '';
  };
in
{
  imports = [ inputs.openai-secure-tunnel-nix.nixosModules.tunnel-client ];

  sops.secrets.openai-tunnel-api-key = {
    sopsFile = ../../../../secrets/openai-tunnel.yaml;
  };

  services.openai-tunnel-client.instances.twitter-api-safe-relay = {
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

  virtualisation.oci-containers.containers =
    (lib.listToAttrs (
      builtins.map (account: {
        name = account.containerName;
        value = {
          image = "kasmweb/chrome:1.18.0@sha256:ae956514c4d034673423c46317a8c5994fe3517b34662155d467e6648571d195";
          ports = [
            "${toString account.browserHostPort}:3000"
            "${toString account.vncHostPort}:6901"
          ];
          volumes = [
            "${account.profileDir}:/home/kasm-user/chrome-profile"
          ];
          environment = {
            VNC_PW = "password";
            APP_ARGS = "--start-maximized --user-data-dir=/home/kasm-user/chrome-profile --password-store=basic --remote-debugging-address=0.0.0.0 --remote-debugging-port=${toString browserDebugPort}";
          };
          extraOptions = [
            "--shm-size=4g"
            "--network=${relayNetworkName}"
            "--network-alias=${account.containerName}"
          ];
        };
      }) accountConfigs
    ))
    // (lib.listToAttrs (
      builtins.map (account: {
        name = account.cdpContainerName;
        value = {
          image = "alpine/socat:1.8.1.3@sha256:f134cb7ebb983f971f5deb44e92bc62c1385b0a3b525393f32dd0722acc30315";
          cmd = [
            "TCP-LISTEN:${toString relayDebugPort},fork,reuseaddr"
            "TCP:127.0.0.1:${toString browserDebugPort}"
          ];
          extraOptions = [
            "--network=container:${account.containerName}"
          ];
        };
      }) accountConfigs
    ));

  services.traefik.dynamicConfigOptions.http = {
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

  systemd = {
    services = {
      twitter-api-safe-relay-network = {
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        before =
          (builtins.map (account: "podman-${account.containerName}.service") accountConfigs)
          ++ (builtins.map (account: "podman-${account.cdpContainerName}.service") accountConfigs)
          ++ [ "twitter-api-safe-relay.service" ];
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
    // lib.listToAttrs (
      builtins.map (account: {
        name = "podman-${account.containerName}";
        value = {
          preStart = ''
            mkdir -p ${account.profileDir}
            rm -f ${account.profileDir}/SingletonLock ${account.profileDir}/SingletonSocket ${account.profileDir}/SingletonCookie ${account.profileDir}/DevToolsActivePort
            chown -R 1000:0 ${account.profileDir}
            chmod -R g+rwX ${account.profileDir}
          '';
          after = [
            "network-online.target"
            "twitter-api-safe-relay-network.service"
          ];
          wants = [ "twitter-api-safe-relay-network.service" ];
          requires = [ "twitter-api-safe-relay-network.service" ];
        };
      }) accountConfigs
    )
    // lib.listToAttrs (
      builtins.map (account: {
        name = "podman-${account.cdpContainerName}";
        value = {
          after = [
            "twitter-api-safe-relay-network.service"
            "podman-${account.containerName}.service"
          ];
          requires = [
            "twitter-api-safe-relay-network.service"
            "podman-${account.containerName}.service"
          ];
          partOf = [ "podman-${account.containerName}.service" ];
        };
      }) accountConfigs
    )
    // {
      tunnel-client-twitter-api-safe-relay = {
        after = [ "twitter-api-safe-relay.service" ];
        wants = [ "twitter-api-safe-relay.service" ];
        serviceConfig.LoadCredential = [
          "${tunnelCredentialName}:${config.sops.secrets.openai-tunnel-api-key.path}"
        ];
      };
      twitter-bookmark-snap = {
        description = "Fetch and render Twitter bookmarks";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment = {
          PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
          FFMPEG_PATH = "${pkgs.ffmpeg}/bin/ffmpeg";
          FFPROBE_PATH = "${pkgs.ffmpeg}/bin/ffprobe";
        };
        serviceConfig = {
          Type = "oneshot";
          User = "yuta";
          WorkingDirectory = "${bookmark-snap}/lib";
        };
        script = ''
          ${lib.getExe pkgs.nodejs} dist/index.js -- --limit 50 --output-dir ${outputDir}
        '';
      };
      twitter-api-safe-relay = {
        description = "Twitter API Safe Relay and MCP server";
        wantedBy = [ "multi-user.target" ];
        preStart = ''
          settings_file="/run/twitter-api-safe-relay/settings.json"
          mkdir -p /run/twitter-api-safe-relay

          settings_profiles=""

          ${lib.concatMapStringsSep "\n" (account: ''
            container=${account.cdpContainerName}
            echo "Waiting for container $container CDP proxy endpoint on port ${toString relayDebugPort}..."
            for i in $(seq 1 30); do
              ip=$(${lib.getExe pkgs.podman} inspect -f '{{range $name, $net := .NetworkSettings.Networks}}{{if eq $name "${relayNetworkName}"}}{{ $net.IPAddress }}{{end}}{{end}}' "$container" 2>/dev/null || true)
              if [ -z "$ip" ] || [ "$ip" = "<no value>" ]; then
                ip=""
              fi

              if [ -n "$ip" ] && ${lib.getExe pkgs.curl} --fail --max-time 2 --silent "http://$ip:${toString relayDebugPort}/json/version" >/dev/null 2>&1; then
                echo "$container ready at $ip:${toString relayDebugPort}"
                break
              fi
              if [ "$i" -eq 30 ]; then
                echo "Timed out waiting for $container CDP endpoint on port ${toString relayDebugPort}" >&2
                exit 1
              fi
              sleep 2
            done

            if [ -z "$ip" ]; then
              echo "Unable to resolve a usable CDP endpoint IP for $container" >&2
              exit 1
            fi

            if [ -n "$settings_profiles" ]; then
              settings_profiles="$settings_profiles,"
            fi
            settings_profiles="$settings_profiles{\"name\":\"${account.name}\",\"browser\":{\"type\":\"cdp\",\"browserType\":\"chromium\",\"cdpEndpoint\":\"http://$ip:${toString relayDebugPort}\"}}"
          '') accountConfigs}

          printf '%s\n' "{\"hostname\":\"127.0.0.1\",\"logger\":{\"level\":\"info\"},\"port\":${toString relayHostPort},\"dashboard\":true,\"mcp\":{\"transport\":\"http\"},\"profiles\":[$settings_profiles]}" > "$settings_file"
        '';
        after = [
          "twitter-api-safe-relay-network.service"
        ]
        ++ (builtins.map (account: "podman-${account.cdpContainerName}.service") accountConfigs);
        wants = [
          "twitter-api-safe-relay-network.service"
        ]
        ++ (builtins.map (account: "podman-${account.cdpContainerName}.service") accountConfigs);
        requires = [
          "twitter-api-safe-relay-network.service"
        ]
        ++ (builtins.map (account: "podman-${account.cdpContainerName}.service") accountConfigs);
        unitConfig = {
          StartLimitIntervalSec = "5m";
          StartLimitBurst = 20;
        };
        serviceConfig = {
          ExecStart = "${package}/bin/twitter-api-safe-mcp /run/twitter-api-safe-relay/settings.json";
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };
    };
    tmpfiles.rules = [
      "d ${outputDir} 0755 yuta users - -"
    ]
    ++ (builtins.map (account: "d ${account.profileDir} 0755 1000 0 - -") accountConfigs);
    timers.twitter-bookmark-snap = {
      description = "Run twitter-bookmark-snap every 15 minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "15min";
        RandomizedDelaySec = "2min";
        Persistent = true;
      };
    };
  };
}
