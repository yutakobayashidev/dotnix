{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.gallery-dl;

  jobUnitName = name: "gallery-dl-job-${name}";

  jsonFormat = pkgs.formats.json { };

  galleryDlConfigDir = "${config.xdg.configHome}/gallery-dl";

  fullSettings = lib.recursiveUpdate cfg.settings {
    extractor.pixiv.refresh-token = config.sops.placeholder."${cfg.sopsSecretName}";
    extractor.pixiv.user-id = config.sops.placeholder."${cfg.sopsPixivUserId}";
    extractor.fanbox.cookies.FANBOXSESSID = config.sops.placeholder."${cfg.sopsFanboxSessid}";
  };

  jobType =
    { name, ... }:
    {
      options = {
        urls = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          description = ''
            A list of URLs to be downloaded by {command}`gallery-dl`.
            See `gallery-dl --list-extractors` for supported sites.
          '';
        };

        startAt = lib.mkOption {
          type = lib.types.str;
          default = "daily";
          description = ''
            Schedule for the download job, in {manpage}`systemd.time(7)` format.
          '';
        };

        extraArgs = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          description = ''
            Job-specific extra arguments passed to {command}`gallery-dl`.
          '';
        };

        settings = lib.mkOption {
          type = jsonFormat.type;
          default = { };
          description = ''
            Job-specific settings overridden on top of the global settings.
          '';
        };
      };
    };
in
{
  options.my.programs.gallery-dl = {
    enable = lib.mkEnableOption "gallery-dl archiving service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.gallery-dl;
      defaultText = lib.literalExpression "pkgs.gallery-dl";
      description = "Package containing the {command}`gallery-dl` binary.";
    };

    archivePath = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.userDirs.pictures}/gallery-dl";
      description = "Default download destination for gallery-dl jobs.";
    };

    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      description = ''
        Global gallery-dl configuration written to `~/.config/gallery-dl/config.json`.
        The Pixiv refresh-token is injected from sops secrets automatically.
      '';
      example = lib.literalExpression ''
        {
          extractor = {
            base-directory = "~/Pictures/gallery-dl";
            archive = "~/Pictures/gallery-dl/archive.sqlite3";
            pixiv = {
              filename = "{id}_p{num}.{extension}";
              directory = ["pixiv" "bookmarks" "{user[id]}_{user[account]}"];
            };
          };
        }
      '';
    };

    extraArgs = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Global arguments passed to every gallery-dl job.";
    };

    sopsSecretName = lib.mkOption {
      type = lib.types.str;
      default = "gallery-dl-pixiv-refresh-token";
      description = "Name of the sops secret containing the Pixiv refresh token.";
    };

    sopsPixivUserId = lib.mkOption {
      type = lib.types.str;
      default = "gallery-dl-pixiv-user-id";
      description = "Name of the sops secret containing the Pixiv user ID.";
    };

    sopsFanboxSessid = lib.mkOption {
      type = lib.types.str;
      default = "gallery-dl-fanbox-sessid";
      description = "Name of the sops secret containing the FANBOXSESSID cookie.";
    };

    sopsFile = lib.mkOption {
      type = lib.types.path;
      default = ./secrets.yaml;
      defaultText = lib.literalExpression "./secrets.yaml";
      description = "Path to the sops-encrypted secrets file.";
    };

    jobs = lib.mkOption {
      type = with lib.types; attrsOf (submodule jobType);
      default = { };
      description = ''
        A map of download jobs. Each job specifies URLs and a schedule.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    sops.secrets.${cfg.sopsSecretName} = {
      sopsFile = cfg.sopsFile;
    };

    sops.secrets.${cfg.sopsPixivUserId} = {
      sopsFile = cfg.sopsFile;
    };

    sops.secrets.${cfg.sopsFanboxSessid} = {
      sopsFile = cfg.sopsFile;
    };

    sops.templates."gallery-dl-config.json" = {
      content = builtins.toJSON fullSettings;
    };

    home.activation.initGalleryDlConfig = lib.hm.dag.entryAfter [ "sops-nix" ] ''
      mkdir -p "${galleryDlConfigDir}"
      ${pkgs.coreutils}/bin/cp ${
        config.sops.templates."gallery-dl-config.json".path
      } "${galleryDlConfigDir}/config.json"
      ${pkgs.coreutils}/bin/chmod 600 "${galleryDlConfigDir}/config.json"
    '';

    systemd.user.services = lib.mapAttrs' (
      name: value:
      lib.nameValuePair (jobUnitName name) {
        Unit = {
          Description = "gallery-dl archive job '${name}'";
          Documentation = [ "man:gallery-dl(1)" ];
        };

        Service = {
          ExecStart =
            let
              jobSettingsFile = jsonFormat.generate "gallery-dl-job-${name}-settings" value.settings;
              runScript = pkgs.writeShellScript "gallery-dl-run-${name}" ''
                PIXIV_ID=$(${lib.getExe pkgs.jq} -r '.extractor.pixiv."user-id"' ${lib.escapeShellArg galleryDlConfigDir}/config.json 2>/dev/null || echo "")
                URLS=()
                for url in ${lib.escapeShellArgs value.urls}; do
                  URLS+=("''${url//\{PIXIV_USER_ID\}/$PIXIV_ID}")
                done
                exec ${lib.getExe cfg.package} \
                  ${lib.escapeShellArgs cfg.extraArgs} \
                  ${lib.escapeShellArgs value.extraArgs} \
                  ${lib.optionalString (value.settings != { }) "--config ${jobSettingsFile}"} \
                  --destination ${lib.escapeShellArg cfg.archivePath} \
                  "''${URLS[@]}"
              '';
            in
            "${runScript}";
          Type = "oneshot";
        };
      }
    ) cfg.jobs;

    systemd.user.timers = lib.mapAttrs' (
      name: value:
      lib.nameValuePair (jobUnitName name) {
        Unit = {
          Description = "gallery-dl archive job '${name}' timer";
          Documentation = [ "man:gallery-dl(1)" ];
        };

        Timer = {
          OnCalendar = value.startAt;
          Persistent = true;
          RandomizedDelaySec = "2min";
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      }
    ) cfg.jobs;
  };
}
