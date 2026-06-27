{
  config,
  lib,
  pkgs,
  ...
}:

let
  tomlFormat = pkgs.formats.toml { };
  hasSecretsFile = builtins.pathExists ./secrets.yaml;
  repairEvery = "30m";

  configFile = tomlFormat.generate "discrawl-config.toml" {
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
      repair_every = repairEvery;
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

  discrawlPackage = lib.hiPrio (
    pkgs.writeShellScriptBin "discrawl" ''
      set -eu
      ${lib.optionalString hasSecretsFile ''
        if [ -z "''${DISCORD_BOT_TOKEN:-}" ]; then
          export DISCORD_BOT_TOKEN="$(${lib.getExe' pkgs.coreutils "cat"} ${config.sops.secrets.discrawl-discord-bot-token.path})"
        fi
      ''}
      export OPENAI_API_KEY="''${OPENAI_API_KEY:-sk-lm-studio}"
      exec ${lib.getExe pkgs.discrawl} "$@"
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
  sops.secrets = lib.optionalAttrs hasSecretsFile {
    discrawl-discord-bot-token.sopsFile = ./secrets.yaml;
  };

  home.packages = [ discrawlPackage ];

  xdg.configFile."discrawl/config.toml".source = configFile;

  systemd.user.services = {
    discrawl-tail = {
      Unit = {
        Description = "Discrawl live Discord archive tail";
        After = [ "network-online.target" ];
      };

      Service = {
        ExecStart = "${discrawl} tail --repair-every ${repairEvery}";
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

  systemd.user.timers.discrawl-maintenance = {
    Unit = {
      Description = "Discrawl periodic maintenance timer";
    };

    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
      Persistent = true;
      RandomizedDelaySec = "2min";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
