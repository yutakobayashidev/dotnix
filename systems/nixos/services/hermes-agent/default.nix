# host hermes-agent.nix
{
  config,
  inputs,
  ...
}:
{
  imports = [
    ./alloy.nix
    inputs.microvm.nixosModules.host
  ];

  sops.secrets = {
    "hermes-agent/slack-bot-token".sopsFile = ./secrets.yaml;
    "hermes-agent/slack-app-token".sopsFile = ./secrets.yaml;
    "hermes-agent/slack-allowed-users".sopsFile = ./secrets.yaml;
    "hermes-agent/auth-json" = {
      sopsFile = ./auth.json;
      format = "binary";
      # microvm@hermes-agent.service runs qemu as microvm:kvm and reads this
      # via SMBIOS OEM strings (microvm.credentialFiles below).
      owner = "microvm";
      group = "kvm";
      mode = "0440";
    };
  };

  sops.templates."hermes-agent.env" = {
    content = ''
      SLACK_BOT_TOKEN=${config.sops.placeholder."hermes-agent/slack-bot-token"}
      SLACK_APP_TOKEN=${config.sops.placeholder."hermes-agent/slack-app-token"}
      SLACK_ALLOWED_USERS=${config.sops.placeholder."hermes-agent/slack-allowed-users"}
      SEARXNG_URL=https://search.home.yutakobayashi.com
      WIKI_PATH=/var/lib/hermes/wiki
    '';
    owner = "microvm";
    group = "kvm";
    mode = "0440";
  };

  microvm.autostart = [ "hermes-agent" ];

  microvm.vms.hermes-agent = {
    extraModules = [
      inputs.hermes-agent.nixosModules.default
    ];

    config = {
      imports = [ ./guest.nix ];
      _module.args.inputs = inputs;

      microvm.credentialFiles = {
        "hermes-agent.env" = config.sops.templates."hermes-agent.env".path;
        "hermes-agent.auth.json" = config.sops.secrets."hermes-agent/auth-json".path;
      };
    };
  };
}
