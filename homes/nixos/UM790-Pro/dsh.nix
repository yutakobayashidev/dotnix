{ config, ... }:

{
  my.programs.dsh.web.settings."llm-pi-ai".providers = {
    # Keep native model catalogs, authentication, and session-header handling.
    openai-codex = { };
    opencode-go = { };
  };

  sops = {
    secrets.dsh-opencode-go-key = {
      sopsFile = ../../../systems/nixos/services/litellm/secrets.yaml;
      key = "litellm/opencode-go-key";
    };
    templates."dsh-web.env" = {
      content = ''
        OPENCODE_API_KEY=${config.sops.placeholder.dsh-opencode-go-key}
      '';
      mode = "0400";
    };
  };

  systemd.user.services.dsh-web = {
    Unit = {
      Requires = [ "sops-nix.service" ];
      After = [ "sops-nix.service" ];
    };
    Service.EnvironmentFile = config.sops.templates."dsh-web.env".path;
  };
}
