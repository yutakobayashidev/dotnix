# host hermes-agent.nix
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./alloy.nix
    inputs.microvm.nixosModules.host
  ];

  sops.secrets = {
    "hermes-agent/ori-mcp-client-secret" = {
      sopsFile = ../../../../secrets/pocket-id-oidc.yaml;
      key = "client-secrets/ori-hermes";
    };
    "hermes-agent/slack-bot-token".sopsFile = ./secrets.yaml;
    "hermes-agent/slack-app-token".sopsFile = ./secrets.yaml;
    "hermes-agent/slack-allowed-users".sopsFile = ./secrets.yaml;
    "hermes-agent/discord-bot-token".sopsFile = ./secrets.yaml;
    "hermes-agent/opencode-go-key".sopsFile = ./secrets.yaml;
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
      OPENCODE_GO_API_KEY=${config.sops.placeholder."hermes-agent/opencode-go-key"}
      ORI_MCP_CLIENT_SECRET=${config.sops.placeholder."hermes-agent/ori-mcp-client-secret"}
      DISCORD_HOME_CHANNEL=1028287639918497822
      BIRD_PROFILE_NAME=account1
      COURSE_API_URL=https://api.nnn.ed.nico/
      COURSE_PAPI_URL=https://papi.nnn.ed.nico/
      COURSE_WEB_URL=https://www.nnn.ed.nico/
      COURSE_COOKIE_NAME=_zane_session
      EDCB_HOST=100.111.109.43
      EDCB_PORT=4510
      EDCB_TIMEOUT_SECONDS=15
      SEARXNG_URL=https://search.home.yutakobayashi.com
      RDT_GATEWAY_URL=https://rdt.home.yutakobayashi.com
      TWITTER_RELAY_BASE_URL=https://tw.home.yutakobayashi.com
      WIKI_PATH=/var/lib/hermes/wiki
      QS_WIKI_PATH=/var/lib/hermes/quantified-self-wiki
    '';
    owner = "microvm";
    group = "kvm";
    mode = "0440";
  };

  microvm.autostart = [ "hermes-agent" ];

  # HTTPS on Tailnet only. Preserve the host's existing Serve root route.
  systemd.services.hermes-mcp-events-serve = {
    description = "Hermes MCP Events HTTPS receiver on Tailnet";
    wantedBy = [ "multi-user.target" ];
    after = [
      "tailscaled.service"
      "microvm@hermes-agent.service"
    ];
    requires = [ "tailscaled.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${lib.getExe pkgs.tailscale} serve --bg --https=443 --set-path=/webhooks http://127.0.0.1:18644/webhooks";
      ExecStop = "${lib.getExe pkgs.tailscale} serve --https=443 --set-path=/webhooks off";
    };
  };

  # Override microvm.nix's default microvm:kvm ownership for this writable wiki.
  systemd.tmpfiles.settings."10-microvm"."/home/yuta/ghq/git.yutakobayashi.com/yuta/quantified-self-wiki".d =
    lib.mkForce {
      user = "yuta";
      group = config.users.users.yuta.group;
      mode = "0750";
    };

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
