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
    "hermes-agent/discord-bot-token".sopsFile = ./secrets.yaml;
    "hermes-agent/discrawl-archive-ssh-key" = {
      sopsFile = ./secrets.yaml;
      # microvm@hermes-agent.service runs qemu as microvm:kvm and reads this
      # via SMBIOS OEM strings (microvm.credentialFiles below).
      owner = "microvm";
      group = "kvm";
      mode = "0400";
    };
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
      SLACK_HOME_CHANNEL=C0B2DC01LJK
      DISCORD_BOT_TOKEN=${config.sops.placeholder."hermes-agent/discord-bot-token"}
      DISCORD_ALLOWED_USERS=890908900520505354
      DISCORD_HOME_CHANNEL=1028287639918497822
      BIRD_PROFILE_NAME=account1
      SEARXNG_URL=https://search.home.yutakobayashi.com
      TWITTER_RELAY_BASE_URL=https://tw.home.yutakobayashi.com
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
      nix.registry.nixpkgs.flake = inputs.nixpkgs;

      microvm.credentialFiles = {
        "hermes-agent.env" = config.sops.templates."hermes-agent.env".path;
        "hermes-agent.auth.json" = config.sops.secrets."hermes-agent/auth-json".path;
        "discrawl.key" = config.sops.secrets."hermes-agent/discrawl-archive-ssh-key".path;
      };
    };
  };
}
