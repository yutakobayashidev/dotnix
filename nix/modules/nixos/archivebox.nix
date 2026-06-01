{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  cfg = config.services.archivebox;
  jobUnitName = name: "archivebox-job-${utils.escapeSystemdPath name}";

  jobType =
    { options, ... }:
    {
      options = {
        urls = lib.mkOption {
          type = with lib.types; listOf str;
          description = "List of links to archive.";
          example = lib.literalExpression ''
            [
              "https://guix.gnu.org/feeds/blog.atom"
              "https://nixos.org/blog/announcements-rss.xml"
            ]
          '';
        };

        opmlFile = lib.mkOption {
          type = with lib.types; nullOr path;
          description = ''
            Path to an OPML file containing links to archive.
            Mutually exclusive with {option}`urls` and {option}`opmlUrl`.
          '';
          default = null;
          example = "/var/lib/archivebox/feeds.opml";
        };

        opmlUrl = lib.mkOption {
          type = with lib.types; nullOr str;
          description = ''
            URL to an OPML file to download and archive.
            Mutually exclusive with {option}`urls` and {option}`opmlFile`.
          '';
          default = null;
          example = "https://radar.yutakobayashi.com/sources.opml";
        };

        extraArgs = lib.mkOption {
          type = with lib.types; listOf str;
          description = ''
            Additional arguments for adding links (i.e., {command}`archivebox add
            $LINK`) from {option}`urls`.
          '';
          default = [ ];
          example = lib.literalExpression ''
            [ "--depth" "1" ]
          '';
        };

        startAt = lib.mkOption {
          type = with lib.types; str;
          description = ''
            Indicates how frequent the scheduled archiving will occur. Should be
            a valid string format as described from {manpage}`systemd.time(5)`.
          '';
          default = "weekly";
          defaultText = "weekly";
          example = "*-*-01/2";
        };
      };
    };

  mkJobService =
    name: value:
    lib.nameValuePair (jobUnitName name) {
      description = "ArchiveBox download group '${name}'";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      documentation = [ "https://docs.archivebox.io/" ];
      path = [ cfg.package ] ++ cfg.extraPackages;
      script =
        if value.urls != [ ] then
          ''
            echo "${lib.concatStringsSep "\n" value.urls}" \
              | archivebox add ${lib.escapeShellArgs value.extraArgs}
          ''
        else if value.opmlFile != null then
          ''
            archivebox add ${lib.escapeShellArgs value.extraArgs} "${value.opmlFile}"
          ''
        else if value.opmlUrl != null then
          ''
            python3 -c "
            import sys, xml.etree.ElementTree as ET, urllib.request
            req = urllib.request.Request('${value.opmlUrl}', headers={'User-Agent': 'Mozilla/5.0 (compatible; ArchiveBox/0.9)'})
            resp = urllib.request.urlopen(req, timeout=10)
            tree = ET.parse(resp)
            for el in tree.iter():
                url = el.get('xmlUrl') or el.get('url') or el.get('htmlUrl')
                if url:
                    print(url)
            " \
              | archivebox add ${lib.escapeShellArgs value.extraArgs}
          ''
        else
          ''
            archivebox add ${lib.escapeShellArgs value.extraArgs}
          '';
      serviceConfig = {
        User = "archivebox";
        Group = "archivebox";
        WorkingDirectory = "/var/lib/archivebox";

        LockPersonality = true;
        NoNewPrivileges = true;

        PrivateTmp = true;
        PrivateDevices = true;

        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectHome = true;
        ProtectSystem = "strict";

        RestrictAddressFamilies = [
          "AF_LOCAL"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;

        SystemCallFilter = [ "@system-service" ];
        SystemCallErrorNumber = "EPERM";

        StateDirectory = "archivebox";
      };
    };

  mkTimerUnit =
    name: value:
    lib.nameValuePair (jobUnitName name) {
      description = "ArchiveBox download job '${name}'";
      documentation = [ "https://docs.archivebox.io/" ];
      timerConfig = {
        Persistent = true;
        OnCalendar = value.startAt;
        RandomizedDelaySec = 120;
      };
      wantedBy = [ "timers.target" ];
    };
in
{
  options.services.archivebox = {
    enable = lib.mkEnableOption "ArchiveBox service";

    package = lib.mkPackageOption pkgs "archivebox" { };

    jobs = lib.mkOption {
      type = with lib.types; attrsOf (submodule jobType);
      description = "A map of archiving tasks for the service.";
      default = { };
      defaultText = lib.literalExpression "{}";
      example = {
        illustration = {
          urls = [
            "https://www.davidrevoy.com/"
            "https://www.youtube.com/c/ronillust"
          ];
          startAt = "weekly";
        };

        research = {
          urls = [
            "https://arxiv.org/rss/cs"
            "https://distill.pub/"
          ];
          extraArgs = [
            "--depth"
            "1"
          ];
          startAt = "daily";
        };
      };
    };

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      description = ''
        A list of additional packages to be set within the download jobs. By
        default, it sets the optional dependencies of ArchiveBox for additional
        download formats and capabilities.
      '';
      default =
        with pkgs;
        [
          chromium
          nodejs_latest
          wget
          curl
          yt-dlp
          python3
          readability-cli
        ]
        ++ lib.optional config.programs.git.enable config.programs.git.package;
      defaultText = ''
        Chromium, NodeJS, wget, curl, yt-dlp, readability-cli, and git if enabled.
      '';
      example = lib.literalExpression ''
        with pkgs; [
          curl
          yt-dlp
        ]
      '';
    };

    webserver = {
      enable = lib.mkEnableOption "ArchiveBox web server";

      port = lib.mkOption {
        type = lib.types.port;
        description = "The port number to be used for the server at localhost.";
        default = 8000;
        example = 8888;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        systemd.services = lib.mapAttrs' mkJobService cfg.jobs;
        systemd.timers = lib.mapAttrs' mkTimerUnit cfg.jobs;

        users.groups.archivebox = { };

        users.users.archivebox = {
          group = config.users.groups.archivebox.name;
          isSystemUser = true;
          home = "/var/lib/archivebox";
        };
      }

      (lib.mkIf cfg.webserver.enable {
        systemd.services.archivebox-server = {
          description = "ArchiveBox web server";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          documentation = [ "https://docs.archivebox.io/" ];
          wantedBy = [ "multi-user.target" ];
          path = [ cfg.package ];
          environment = {
            PYTHONPATH = lib.makeSearchPath "lib/${pkgs.python3.libPrefix}/site-packages" (
              lib.closePropagation ([ cfg.package ] ++ (cfg.package.propagatedBuildInputs or [ ]))
            );
            BASE_URL = "https://archive.home.yutakobayashi.com";
            SERVER_SECURITY_MODE = "danger-onedomain-fullreplay";
          };
          serviceConfig = {
            User = "archivebox";
            Group = "archivebox";
            WorkingDirectory = "/var/lib/archivebox";

            ExecStart = "${lib.getExe' cfg.package "archivebox"} server localhost:${toString cfg.webserver.port}";

            CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];

            Restart = "on-failure";
            LockPersonality = true;
            NoNewPrivileges = true;

            PrivateTmp = true;
            PrivateUsers = true;
            PrivateDevices = true;
            ProtectControlGroups = true;
            ProtectClock = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;

            RestrictAddressFamilies = [
              "AF_LOCAL"
              "AF_INET"
              "AF_INET6"
              "AF_NETLINK"
              "AF_PACKET"
            ];
            RestrictNamespaces = true;

            SystemCallFilter = [ "@system-service" ];
            SystemCallErrorNumber = "EPERM";
            StateDirectory = "archivebox";
          };
        };
      })
    ]
  );
}
