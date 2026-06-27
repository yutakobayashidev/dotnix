{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  agentSkillsLib = inputs.agent-skills.lib.agent-skills;
  hermesSkillsSources = {
    superpowers = {
      path = inputs.superpowers;
      subdir = "skills";
    };
    skills = {
      path = inputs.skills;
      subdir = "skills";
    };
  };
  hermesSkillsCatalog = agentSkillsLib.discoverCatalog hermesSkillsSources;
  hermesSkillsSelection = agentSkillsLib.selectSkills {
    catalog = hermesSkillsCatalog;
    sources = hermesSkillsSources;
    skills = {
      brainstorming = {
        from = "superpowers";
        path = "brainstorming";
      };
      bird = {
        from = "skills";
        path = "bird";
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
  environment.systemPackages = [
    inputs.bird.packages.${pkgs.stdenv.hostPlatform.system}.bird
  ];

  networking.hosts = {
    "100.111.109.43" = [ "tw.home.yutakobayashi.com" ];
  };

  microvm = {
    vcpu = 2;
    mem = 4096;

    interfaces = [
      {
        type = "user";
        id = "hermes-net";
        mac = "02:00:00:00:48:01";
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
        source = "/home/yuta/ghq/git.yutakobayashi.com/yuta/llm-wiki";
        mountPoint = "/var/lib/hermes/workspace/llm-wiki";
        tag = "llm-wiki";
        proto = "virtiofs";
      }
    ];

    volumes = [
      {
        image = "state.img";
        mountPoint = "/var/lib/hermes";
        size = 4096;
        label = "hermes-state";
      }
    ];
  };

  services.hermes-agent = {
    enable = true;
    extraDependencyGroups = [ "slack" ];

    settings = {
      model.provider = "openai-codex";
      web.search_backend = "searxng";

      slack = {
        channel_prompts = { };
      };
    };
  };

  users.users.hermes.uid = 1000;

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

      install -o hermes -g hermes -m 0640 \
        ${hermesConfigFile} /var/lib/hermes/.hermes/config.yaml

      install -o hermes -g hermes -m 0640 \
        ${hermesAgentsFile} /var/lib/hermes/.hermes/AGENTS.md

      install -o hermes -g hermes -m 0640 \
        ${hermesSoulFile} /var/lib/hermes/.hermes/SOUL.md

      install -o hermes -g hermes -m 0640 \
        ${credentialsDir}/hermes-agent.env /var/lib/hermes/.hermes/.env

      echo 'TWITTER_RELAY_BASE_URL=https://tw.home.yutakobayashi.com' \
        >> /var/lib/hermes/.hermes/.env

      if [ ! -f /var/lib/hermes/.hermes/auth.json ]; then
        install -o hermes -g hermes -m 0600 \
          ${credentialsDir}/hermes-agent.auth.json /var/lib/hermes/.hermes/auth.json
      fi

      ${hermesSkillsInstallScript}
    '';
  };

  services.journald.extraConfig = ''
    ForwardToConsole=yes
    MaxLevelConsole=info
  '';

  system.stateVersion = "25.11";
}
