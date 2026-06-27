{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.programs.discrawl;
  tomlFormat = pkgs.formats.toml { };

  defaultSettings = {
    version = 1;
    default_guild_id = "895564066922328094";
    guild_ids = [ "895564066922328094" ];
    db_path = "~/.local/share/discrawl/discrawl.db";
    cache_dir = "~/.cache/discrawl";
    log_dir = "~/.local/state/discrawl/logs";

    discord = {
      token_source = "env";
      token_env = "DISCORD_BOT_TOKEN";
      token_keyring_service = "discrawl";
      token_keyring_account = "discord_bot_token";
    };

    sync = {
      source = "discord";
      concurrency = 16;
      repair_every = cfg.systemd.repairEvery;
      full_history = true;
      attachment_text = true;
      attachment_media = false;
      max_attachment_bytes = 104857600;
    };

    desktop = {
      path = "~/.config/discord";
      max_file_bytes = 67108864;
      full_cache = false;
    };

    search = {
      default_mode = "fts";

      embeddings = {
        enabled = true;
        provider = "openai_compatible";
        model = "text-embedding-bge-m3";
        base_url = "http://x870-stell-legend.tail29d068.ts.net:1234/v1";
        api_key_env = "OPENAI_API_KEY";
        batch_size = 64;
        max_input_chars = 12000;
        request_timeout = "2m";
        vector_backend = "exact";
      };
    };

    share = {
      remote = "https://git.yutakobayashi.com/yuta/discord-archive";
      repo_path = "~/ghq/git.yutakobayashi.com/yuta/discord-archive";
      branch = "main";
      auto_update = true;
      stale_after = "15m";
      media = false;

      filter = {
        public_only = false;
        include_channel_ids = [ ];
        exclude_channel_ids = [ ];
      };
    };

    remote = {
      mode = "local";
      endpoint = "";
      archive = "";
      token_env = "DISCRAWL_REMOTE_TOKEN";
      stale_after = "";
    };
  };

  settings = lib.recursiveUpdate defaultSettings cfg.settings;
  configFile = tomlFormat.generate "discrawl-config.toml" settings;

  discrawlPackage = lib.hiPrio (
    pkgs.writeShellScriptBin "discrawl" ''
      set -eu
      ${lib.optionalString (cfg.sopsFile != null) ''
        if [ -z "''${DISCORD_BOT_TOKEN:-}" ]; then
          export DISCORD_BOT_TOKEN="$(${lib.getExe' pkgs.coreutils "cat"} ${
            config.sops.secrets.${cfg.sopsSecretName}.path
          })"
        fi
      ''}
      export OPENAI_API_KEY="''${OPENAI_API_KEY:-sk-lm-studio}"
      exec ${lib.getExe cfg.package} "$@"
    ''
  );
  discrawl = "${discrawlPackage}/bin/discrawl";

  maintenanceScript = pkgs.writeShellScript "discrawl-maintenance" ''
    set -eu

    ${lib.getExe' pkgs.systemd "systemctl"} --user stop discrawl-tail.service || true
    trap '${lib.getExe' pkgs.systemd "systemctl"} --user start discrawl-tail.service || true' EXIT

    ${discrawl} sync --with-embeddings --with-members --all-channels
    ${discrawl} embed --limit 10000
    ${discrawl} publish --push
  '';
in
{
  options.my.programs.discrawl = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.discrawl;
      defaultText = lib.literalExpression "pkgs.discrawl";
      description = "Package containing the {command}`discrawl` binary used by the systemd units.";
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = "Discrawl configuration written to `~/.config/discrawl/config.toml`.";
    };

    sopsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the sops-encrypted file containing the Discord bot token.";
    };

    sopsSecretName = lib.mkOption {
      type = lib.types.str;
      default = "discrawl-discord-bot-token";
      description = "Name of the sops secret containing the Discord bot token.";
    };

    systemd = {
      enable = lib.mkEnableOption "Discrawl user services and timers";

      repairEvery = lib.mkOption {
        type = lib.types.str;
        default = "30m";
        description = "Repair interval passed to `discrawl tail` and the generated config.";
      };

      maintenanceInterval = lib.mkOption {
        type = lib.types.str;
        default = "30min";
        description = "Interval for periodic sync, embedding, and Git publish.";
      };
    };
  };

  config = lib.mkIf cfg.systemd.enable {
    sops.secrets = lib.optionalAttrs (cfg.sopsFile != null) {
      ${cfg.sopsSecretName}.sopsFile = cfg.sopsFile;
    };

    xdg.configFile."discrawl/config.toml".source = configFile;

    systemd.user.services = {
      discrawl-tail = {
        Unit = {
          Description = "Discrawl live Discord archive tail";
          After = [ "network-online.target" ];
        };

        Service = {
          ExecStart = "${discrawl} tail --repair-every ${cfg.systemd.repairEvery}";
          Restart = "always";
          RestartSec = "30s";
          WorkingDirectory = "%h";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      discrawl-maintenance = {
        Unit = {
          Description = "Discrawl periodic sync, embedding, and Git publish";
          After = [ "network-online.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = maintenanceScript;
          WorkingDirectory = "%h";
        };
      };
    };

    systemd.user.timers = {
      discrawl-maintenance = {
        Unit = {
          Description = "Discrawl periodic maintenance timer";
        };

        Timer = {
          OnBootSec = "5min";
          OnUnitActiveSec = cfg.systemd.maintenanceInterval;
          Persistent = true;
          RandomizedDelaySec = "2min";
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
  };
}
