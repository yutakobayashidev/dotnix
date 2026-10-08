{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  app = inputs.twitter-lite.packages.${pkgs.stdenv.hostPlatform.system}.default;
  runtime = inputs.twitter-lite.packages.${pkgs.stdenv.hostPlatform.system}.workspace-runtime;
  node = lib.getExe pkgs.nodejs_22;
  stateDir = "${config.xdg.stateHome}/twitter-lite";
  reportDir = "${stateDir}/research";
  credentialKey = "${stateDir}/credential-key";
  runtimeToken = "${stateDir}/runtime-token";
  initializeState = pkgs.writeText "twitter-lite-initialize.mjs" ''
    import { mkdirSync, writeFileSync } from 'node:fs';
    import { randomBytes } from 'node:crypto';

    mkdirSync(${builtins.toJSON reportDir}, { recursive: true, mode: 0o700 });
    for (const file of [${builtins.toJSON credentialKey}, ${builtins.toJSON runtimeToken}]) {
    try {
      writeFileSync(file, randomBytes(32).toString('base64') + '\n', {
        flag: 'wx',
        mode: 0o600,
      });
    } catch (error) {
      if (error.code !== 'EEXIST') throw error;
    }
    }
  '';
  sharedEnvironment = [
    "NODE_ENV=production"
    "TWITTER_LITE_DB_PATH=${stateDir}/workspace.sqlite"
    "TWITTER_LITE_CREDENTIAL_KEY_FILE=${credentialKey}"
    "TWITTER_LITE_BEEPER_CLI=${lib.getExe pkgs.beeper-cli}"
    "TWITTER_LITE_BEEPER_TARGET=um790"
  ];
  environment = sharedEnvironment ++ [
    "WORKSPACE_RUNTIME_URL=http://127.0.0.1:4318"
    "WORKSPACE_RUNTIME_TOKEN_FILE=${runtimeToken}"
    "TWITTER_LITE_REPORT_ROOT=${reportDir}"
    "CODEX_HOME=${config.xdg.configHome}/codex"
    "PATH=${
      lib.makeBinPath [
        config.programs.codex.package
        pkgs.nodejs_22
        pkgs.coreutils
      ]
    }:${config.home.profileDirectory}/bin:${config.home.homeDirectory}/.local/bin:/run/current-system/sw/bin"
    "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
  ];
in
{
  systemd.user.services = {
    twitter-lite-runtime = {
      Unit.Description = "Personal Workspace AI execution runtime";
      Service = {
        ExecStartPre = "${node} ${initializeState}";
        ExecStart = "${runtime}/bin/workspace_runtime start";
        WorkingDirectory = config.home.homeDirectory;
        Environment = [
          "WORKSPACE_RUNTIME_ROOT=${stateDir}/execution"
          "WORKSPACE_RUNTIME_TOKEN_FILE=${runtimeToken}"
          "WORKSPACE_RUNTIME_PORT=4318"
          "WORKSPACE_RUNTIME_CONCURRENCY=2"
          "WORKSPACE_CODEX_PATH=${lib.getExe config.programs.codex.package}"
          "CODEX_HOME=${config.xdg.configHome}/codex"
          "RELEASE_DISTRIBUTION=none"
          "RELEASE_COOKIE=workspace_runtime_local"
          "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
          "PATH=${
            lib.makeBinPath [
              config.programs.codex.package
              pkgs.nodejs_22
              pkgs.coreutils
            ]
          }:${config.home.profileDirectory}/bin:${config.home.homeDirectory}/.local/bin:/run/current-system/sw/bin"
        ];
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
    twitter-lite-events = {
      Unit = {
        Description = "Personal Workspace Beeper events and MCP webhook delivery";
        Wants = [ "beeper-server.service" ];
        After = [ "beeper-server.service" ];
      };
      Service = {
        ExecStartPre = "${node} ${initializeState}";
        ExecStart = "${app}/bin/twitter-lite-events-worker";
        WorkingDirectory = config.home.homeDirectory;
        Environment = sharedEnvironment ++ [
          "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
        ];
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
    twitter-lite = {
      Unit = {
        Description = "Personal Workspace";
        Wants = [ "twitter-lite-runtime.service" ];
        After = [ "twitter-lite-runtime.service" ];
      };
      Service = {
        ExecStartPre = "${node} ${initializeState}";
        ExecStart = lib.getExe app;
        WorkingDirectory = config.home.homeDirectory;
        Environment = environment ++ [
          "HOST=100.91.91.87"
          "PORT=3006"
          "TWITTER_LITE_AUTH_MODE=none"
          "TWITTER_LITE_MCP_URL=http://100.91.91.87:3006/mcp"
          "TWITTER_LITE_ORIGIN=https://tw-lite.home.yutakobayashi.com"
          "TWITTER_RELAY_BASE_URL=https://tw.home.yutakobayashi.com"
          "TWITTER_LITE_MASTODON_ORIGINS=https://fedi.yutakobayashi.com"
          "TWITTER_LITE_CODEX_MODEL=gpt-6-astra"
        ];
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
