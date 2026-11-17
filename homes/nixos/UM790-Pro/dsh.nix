{
  config,
  lib,
  pkgs,
  ...
}:

let
  unpaywallEnv = {
    UNPAYWALL_EMAIL = "hi@yutakobayashi.com";
  };
  stdio = package: env: {
    transport = "stdio";
    command = "${pkgs.bun}/bin/bunx";
    args = [ package ];
    env = env // {
      PATH = lib.makeBinPath [
        pkgs.nodejs
        pkgs.bun
      ];
    };
    startupTimeoutMs = 30000;
    toolCallTimeoutMs = 30000;
  };
  logging = {
    MCP_LOG_LEVEL = "info";
    MCP_TRANSPORT_TYPE = "stdio";
  };
in

{
  my.programs.dsh.web = {
    herdrBridge.enable = true;
    mcpServers = {
      clinicaltrials = stdio "clinicaltrialsgov-mcp-server@latest" logging;
      crossref = {
        transport = "streamable-http";
        url = "https://crossref.caseyjhand.com/mcp";
        startupTimeoutMs = 30000;
        toolCallTimeoutMs = 30000;
      };
      # Anonymous access: optional credential references would block startup
      # when the user has not registered those credentials in DSH.
      openalex = stdio "@cyanheads/openalex-mcp-server@latest" logging;
      pubmed = stdio "@cyanheads/pubmed-mcp-server@latest" (logging // unpaywallEnv);
      semantic-scholar = stdio "@xbghc/semanticscholar-mcp" { };
      unpaywall = stdio "unpaywall-mcp" unpaywallEnv;

      # Local Atuin: cross-harness thread search + shell history for the DSH model.
      atuin = {
        transport = "stdio";
        command = lib.getExe config.programs.atuin.package;
        args = [ "mcp" ];
      };
    };

    settings."llm-pi-ai".providers = {
      # Keep native model catalogs, authentication, and session-header handling.
      openai-codex = { };
      opencode-go = { };
    };

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
