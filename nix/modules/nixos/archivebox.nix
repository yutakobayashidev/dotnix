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
          default = [ ];
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
          description = "Additional arguments for {command}`archivebox add`.";
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
      after = [
        "podman-archivebox.service"
        "network-online.target"
      ];
      requires = [ "podman-archivebox.service" ];
      wants = [ "network-online.target" ];
      documentation = [ "https://docs.archivebox.io/" ];
      path = [
        pkgs.podman
        pkgs.python3
      ];
      script =
        let
          archiveboxAdd = "podman exec -i --user=archivebox archivebox archivebox add ${lib.escapeShellArgs value.extraArgs}";
        in
        if value.urls != [ ] then
          ''
            echo "${lib.concatStringsSep "\n" value.urls}" | ${archiveboxAdd}
          ''
        else if value.opmlFile != null then
          ''
            python3 -c "
            import xml.etree.ElementTree as ET
            tree = ET.parse('${value.opmlFile}')
            for el in tree.iter():
                url = el.get('xmlUrl') or el.get('url') or el.get('htmlUrl')
                if url:
                    print(url)
            " | ${archiveboxAdd}
          ''
        else if value.opmlUrl != null then
          ''
            python3 -c "
            import xml.etree.ElementTree as ET, urllib.request
            req = urllib.request.Request('${value.opmlUrl}', headers={'User-Agent': 'Mozilla/5.0 (compatible; ArchiveBox/0.9)'})
            resp = urllib.request.urlopen(req, timeout=10)
            tree = ET.parse(resp)
            for el in tree.iter():
                url = el.get('xmlUrl') or el.get('url') or el.get('htmlUrl')
                if url:
                    print(url)
            " | ${archiveboxAdd}
          ''
        else
          ''
            ${archiveboxAdd}
          '';
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
    enable = lib.mkEnableOption "ArchiveBox scheduled jobs";

    jobs = lib.mkOption {
      type = with lib.types; attrsOf (submodule jobType);
      description = "A map of archiving tasks for the ArchiveBox container.";
      default = { };
      defaultText = lib.literalExpression "{}";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = lib.mapAttrs' mkJobService cfg.jobs;
    systemd.timers = lib.mapAttrs' mkTimerUnit cfg.jobs;
  };
}
