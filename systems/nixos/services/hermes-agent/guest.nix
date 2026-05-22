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
  };
  hermesSkillsCatalog = agentSkillsLib.discoverCatalog hermesSkillsSources;
  hermesSkillsSelection = agentSkillsLib.selectSkills {
    catalog = hermesSkillsCatalog;
    sources = hermesSkillsSources;
    skills.brainstorming = {
      from = "superpowers";
      path = "brainstorming";
    };
  };
  hermesSkillsBundle = agentSkillsLib.mkBundle {
    inherit pkgs;
    selection = hermesSkillsSelection;
    name = "hermes-agent-skills";
  };
  hermesConfigFile = pkgs.writeText "hermes-config.yaml" (
    builtins.toJSON config.services.hermes-agent.settings
  );
  hermesAgentsFile = ./documents/AGENTS.md;
  hermesSoulFile = ./documents/SOUL.md;
  credentialsDir = "/run/credentials/@system";
in
{
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

    settings = {
      model.provider = "openai-codex";

      slack = {
        channel_prompts = { };
      };
    };
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

      install -o hermes -g hermes -m 0640 \
        ${hermesConfigFile} /var/lib/hermes/.hermes/config.yaml

      install -o hermes -g hermes -m 0640 \
        ${hermesAgentsFile} /var/lib/hermes/.hermes/AGENTS.md

      install -o hermes -g hermes -m 0640 \
        ${hermesSoulFile} /var/lib/hermes/.hermes/SOUL.md

      install -o hermes -g hermes -m 0640 \
        ${credentialsDir}/hermes-agent.env /var/lib/hermes/.hermes/.env

      if [ ! -f /var/lib/hermes/.hermes/auth.json ]; then
        install -o hermes -g hermes -m 0600 \
          ${credentialsDir}/hermes-agent.auth.json /var/lib/hermes/.hermes/auth.json
      fi

      ${lib.getExe pkgs.rsync} -aL --delete \
        ${hermesSkillsBundle}/brainstorming/ /var/lib/hermes/.hermes/skills/brainstorming/
      chown -R hermes:hermes /var/lib/hermes/.hermes/skills/brainstorming
    '';
  };

  services.journald.extraConfig = ''
    ForwardToConsole=yes
    MaxLevelConsole=info
  '';

  system.stateVersion = "25.11";
}
