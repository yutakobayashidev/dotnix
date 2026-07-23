{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  agentSkillsLib = inputs.agent-skills.lib.agent-skills;
  edcbToolsPackage = pkgs.edcb-tools;
  tomlFormat = pkgs.formats.toml { };
  discrawlConfigFile = tomlFormat.generate "discrawl-config.toml" {
    version = 1;
    default_guild_id = "895564066922328094";
    guild_ids = [ "895564066922328094" ];
    db_path = "/var/lib/hermes/.local/share/discrawl/discrawl.db";
    cache_dir = "/var/lib/hermes/.cache/discrawl";
    log_dir = "/var/lib/hermes/.local/state/discrawl/logs";

    discord = {
      token_source = "none";
      token_env = "DISCORD_BOT_TOKEN";
      token_keyring_service = "discrawl";
      token_keyring_account = "discord_bot_token";
    };

    desktop = {
      path = "/var/lib/hermes/.config/discord";
      max_file_bytes = 67108864;
      full_cache = false;
    };

    sync = {
      source = "both";
      concurrency = 32;
      repair_every = "6h";
      full_history = true;
      attachment_text = true;
      attachment_media = false;
      max_attachment_bytes = 104857600;
    };

    search = {
      default_mode = "fts";

      embeddings = {
        enabled = false;
        provider = "openai";
        model = "text-embedding-3-small";
        base_url = "";
        api_key_env = "OPENAI_API_KEY";
        batch_size = 64;
        max_input_chars = 12000;
        request_timeout = "2m";
        vector_backend = "exact";
      };
    };

    share = {
      remote = "gitea@git-discrawl-archive:yuta/discord-archive.git";
      repo_path = "/var/lib/hermes/.local/share/discrawl/share";
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

      auth = {
        token_source = "";
        keyring_service = "";
        keyring_account = "";
      };
    };
  };
  giteaKnownHosts = pkgs.writeText "hermes-gitea-known-hosts" ''
    git-discrawl-archive,git-ssh.yutakobayashi.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMPZl6HOE9OLZQxnK1liKwcFUSNHKVk0YPC49tdyxHO/
  '';
  hermesSkillsSources = {
    ax = {
      path = inputs.ax;
      subdir = "skills";
    };
    superpowers = {
      path = inputs.superpowers;
      subdir = "skills";
    };
    skills = {
      path = inputs.skills;
      subdir = "skills";
    };
    obsidian-skills = {
      path = inputs.obsidian-skills;
      subdir = "skills";
    };
    openclaw-skills = {
      path = inputs.openclaw;
      subdir = ".agents/skills";
    };
    edcb-tools = {
      path = inputs.edcb-tools;
      subdir = ".agents/skills";
    };
    i-have-adhd = {
      path = inputs.i-have-adhd-skill;
      subdir = "skills";
    };
  };
  hermesSkillsCatalog = agentSkillsLib.discoverCatalog hermesSkillsSources;
  hermesSkillsSelection = agentSkillsLib.selectSkills {
    catalog = hermesSkillsCatalog;
    sources = hermesSkillsSources;
    skills = {
      ax = {
        from = "ax";
        path = "ax";
      };
      brainstorming = {
        from = "superpowers";
        path = "brainstorming";
      };
      bird = {
        from = "skills";
        path = "bird";
      };
      defuddle = {
        from = "obsidian-skills";
        path = "defuddle";
      };
      discrawl = {
        from = "openclaw-skills";
        path = "discrawl";
      };
      edcb-tools = {
        from = "edcb-tools";
        path = "edcb-tools";
        packages = [ edcbToolsPackage ];
      };
      i-have-adhd = {
        from = "i-have-adhd";
        path = "i-have-adhd";
      };
    };
  };
  hermesSkillsBundle = agentSkillsLib.mkBundle {
    inherit pkgs;
    selection = hermesSkillsSelection;
    name = "hermes-agent-skills";
  };
  hermesSkillsInstallScript = lib.concatMapStringsSep "\n" (skill: ''
    install -d -o hermes -g hermes -m 2770 \
      /var/lib/hermes/.hermes/skills/${skill}
    ${lib.getExe pkgs.rsync} -aL --delete \
      ${hermesSkillsBundle}/${skill}/ /var/lib/hermes/.hermes/skills/${skill}/
    chown -R hermes:hermes /var/lib/hermes/.hermes/skills/${skill}
  '') (builtins.attrNames hermesSkillsSelection);
  hermesConfigFile = pkgs.writeText "hermes-config.yaml" (
    builtins.toJSON config.services.hermes-agent.settings
  );
  hermesAgentsFile = ./documents/AGENTS.md;
  hermesSoulFile = ./documents/SOUL.md;
  credentialsDir = "/run/credentials/@system";
in
{
  networking.hosts = {
    "100.111.109.43" = [ "tw.home.yutakobayashi.com" ];
  };

  microvm = {
    vcpu = 2;
    mem = 8192;

    vsock = {
      cid = 48;
      ssh.enable = true;
    };

    interfaces = [
      {
        type = "user";
        id = "hermes-net";
        mac = "02:00:00:00:48:01";
      }
    ];

    # Writable upper for /nix/store so the agent can `nix shell nixpkgs#...`.
    # microvm.nix requires auto-optimise-store to be disabled with this.
    writableStoreOverlay = "/nix/.rw-store";

    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
      {
        source = "/home/yuta/ghq/git.yutakobayashi.com/yuta/llm-wiki";
        mountPoint = "/var/lib/hermes/wiki";
        tag = "llm-wiki";
        proto = "virtiofs";
      }
      {
        source = "/home/yuta/ghq/git.yutakobayashi.com/yuta/life";
        mountPoint = "/var/lib/hermes/ghq/git.yutakobayashi.com/yuta/life";
        tag = "life";
        proto = "virtiofs";
      }
      {
        source = "/home/yuta/ghq/github.com/yutakobayashidev/awesome-adhd";
        mountPoint = "/var/lib/hermes/awesome-adhd";
        tag = "awesome-adhd";
        proto = "virtiofs";
      }
    ];

    volumes = [
      {
        image = "state.img";
        mountPoint = "/var/lib/hermes";
        size = 16384;
        label = "hermes-state";
      }
      {
        image = "nix-overlay.img";
        mountPoint = "/nix/.rw-store";
        size = 8192;
        label = "hermes-nix-rw";
      }
    ];
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = false;
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    extraDependencyGroups = [ "messaging" ];
    extraPackages = [
      pkgs.ax
      edcbToolsPackage
      pkgs.bird
      pkgs.cloudflared
      pkgs.course-cli
      pkgs.curl
      pkgs.curl-impersonate
      pkgs.defuddle
      pkgs.discrawl
      pkgs.duckdb
      pkgs.fd
      pkgs.ffmpeg
      pkgs.gh
      pkgs.ghq
      pkgs.git
      pkgs.imagemagick
      pkgs.jq
      pkgs.just
      pkgs.katasu
      pkgs.miller
      pkgs.nature-remo-cli
      pkgs.nlobby-cli
      pkgs.pandoc
      pkgs.poppler-utils
      pkgs.python3
      pkgs.ripgrep
      pkgs.shellcheck
      pkgs.shfmt
      pkgs.sqlite
      pkgs.uv
      pkgs.xan
      pkgs.yq-go
    ];

    settings = {
      group_sessions_per_user = true;
      model.provider = "openai-codex";
      web.search_backend = "searxng";
      compression = {
        threshold = 0.85;
        codex_gpt55_autoraise = true;
      };

      discord = {
        require_mention = true;
        thread_require_mention = false;
        auto_thread = true;
        reactions = true;
        history_backfill = true;
        history_backfill_limit = 50;
        allow_mentions = {
          everyone = false;
          roles = false;
          users = true;
          replied_user = true;
        };
      };

      slack = {
        channel_prompts = { };
      };
    };
  };

  users.users = {
    hermes.uid = 1000;

    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBHugSM9g92mo7bMp4jE2P9TLddbzqhyvRJ9qy/ZkUR hermes microvm root temporary key; rotate to yubikey"
    ];
  };

  systemd.services.hermes-agent-secrets-seed = {
    description = "Seed hermes-agent config and secrets from systemd credentials";
    wantedBy = [ "hermes-agent.service" ];
    before = [ "hermes-agent.service" ];
    unitConfig.RequiresMountsFor = [ "/var/lib/hermes" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      install -d -o hermes -g hermes -m 2770 /var/lib/hermes/.hermes
      install -d -o hermes -g hermes -m 2770 /var/lib/hermes/.hermes/skills
      install -d -o hermes -g hermes -m 2770 /var/lib/hermes/workspace
      install -d -o hermes -g hermes -m 0750 /var/lib/hermes/.config
      install -d -o hermes -g hermes -m 0750 /var/lib/hermes/.config/discrawl
      install -d -o hermes -g hermes -m 0750 /var/lib/hermes/.cache
      install -d -o hermes -g hermes -m 0750 /var/lib/hermes/.local
      install -d -o hermes -g hermes -m 0750 /var/lib/hermes/.local/share
      install -d -o hermes -g hermes -m 0750 /var/lib/hermes/.local/state
      install -d -o hermes -g hermes -m 0700 /var/lib/hermes/.ssh

      install -o hermes -g hermes -m 0640 \
        ${hermesConfigFile} /var/lib/hermes/.hermes/config.yaml

      install -o hermes -g hermes -m 0640 \
        ${hermesAgentsFile} /var/lib/hermes/.hermes/AGENTS.md

      install -o hermes -g hermes -m 0640 \
        ${hermesSoulFile} /var/lib/hermes/.hermes/SOUL.md

      install -o hermes -g hermes -m 0640 \
        ${discrawlConfigFile} /var/lib/hermes/.config/discrawl/config.toml

      install -o hermes -g hermes -m 0640 \
        ${credentialsDir}/hermes-agent.env /var/lib/hermes/.hermes/.env

      install -o hermes -g hermes -m 0600 \
        ${credentialsDir}/discrawl.key \
        /var/lib/hermes/.ssh/discrawl_archive_ed25519

      install -o hermes -g hermes -m 0644 \
        ${giteaKnownHosts} /var/lib/hermes/.ssh/known_hosts

      cat > /var/lib/hermes/.ssh/config <<'EOF'
      Host git-discrawl-archive
        HostName git-ssh.yutakobayashi.com
        User gitea
        IdentityFile /var/lib/hermes/.ssh/discrawl_archive_ed25519
        IdentitiesOnly yes
        IdentityAgent none
        BatchMode yes
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        ProxyCommand ${lib.getExe pkgs.cloudflared} access ssh --hostname %h
        StrictHostKeyChecking yes
        UserKnownHostsFile /var/lib/hermes/.ssh/known_hosts
      EOF
      chown hermes:hermes /var/lib/hermes/.ssh/config
      chmod 0600 /var/lib/hermes/.ssh/config

      # Codex refreshes auth.json in-place. Re-seed only when the deployed
      # sops credential changes, so refreshed tokens survive ordinary rebuilds.
      cred=${credentialsDir}/hermes-agent.auth.json
      stamp=/var/lib/hermes/.hermes/.auth.json.seed-hash
      hash=$(sha256sum "$cred" | cut -d' ' -f1)
      if [ "$(cat "$stamp" 2>/dev/null)" != "$hash" ]; then
        install -o hermes -g hermes -m 0600 \
          "$cred" /var/lib/hermes/.hermes/auth.json
        printf '%s\n' "$hash" > "$stamp"
        chown hermes:hermes "$stamp"
        chmod 0600 "$stamp"
      fi

      ${hermesSkillsInstallScript}

      chown -R hermes:hermes \
        /var/lib/hermes/.hermes \
        /var/lib/hermes/.cache \
        /var/lib/hermes/.config \
        /var/lib/hermes/.local \
        /var/lib/hermes/.ssh \
        /var/lib/hermes/workspace
    '';
  };

  services.journald.extraConfig = ''
    ForwardToConsole=yes
    MaxLevelConsole=info
  '';

  system.stateVersion = "25.11";
}
