{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  app = inputs.twitter-lite.packages.${pkgs.stdenv.hostPlatform.system}.default;
  node = lib.getExe pkgs.nodejs_22;
  stateDir = "${config.xdg.stateHome}/twitter-lite";
  reportDir = "${stateDir}/research";
  credentialKey = "${stateDir}/credential-key";
  codexUrl = "ws://127.0.0.1:4501";
  initializeState = pkgs.writeText "twitter-lite-initialize.mjs" ''
    import { mkdirSync, writeFileSync } from 'node:fs';
    import { randomBytes } from 'node:crypto';

    mkdirSync(${builtins.toJSON reportDir}, { recursive: true, mode: 0o700 });
    try {
      writeFileSync(${builtins.toJSON credentialKey}, randomBytes(32).toString('base64') + '\n', {
        flag: 'wx',
        mode: 0o600,
      });
    } catch (error) {
      if (error.code !== 'EEXIST') throw error;
    }
  '';
  environment = [
    "TWITTER_LITE_CODEX_URL=${codexUrl}"
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
    twitter-lite = {
      Unit = {
        Description = "Twitter Lite research decks";
        Wants = [ "twitter-lite-codex.service" ];
        After = [ "twitter-lite-codex.service" ];
      };
      Service = {
        ExecStartPre = "${node} ${initializeState}";
        ExecStart = lib.getExe app;
        WorkingDirectory = config.home.homeDirectory;
        Environment = environment ++ [
          "NODE_ENV=production"
          "HOST=100.91.91.87"
          "PORT=3006"
          "TWITTER_LITE_AUTH_MODE=none"
          "TWITTER_LITE_ORIGIN=https://tw-lite.home.yutakobayashi.com"
          "TWITTER_RELAY_BASE_URL=https://tw.home.yutakobayashi.com"
          "TWITTER_LITE_DB_PATH=${stateDir}/workspace.sqlite"
          "TWITTER_LITE_CREDENTIAL_KEY_FILE=${credentialKey}"
          "TWITTER_LITE_MASTODON_ORIGINS=https://fedi.yutakobayashi.com"
          "TWITTER_LITE_CODEX_MODEL=gpt-6-astra"
        ];
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };

    twitter-lite-codex = {
      Unit.Description = "Codex app-server for Twitter Lite";
      Service = {
        ExecStart = "${node} ${inputs.twitter-lite}/scripts/serve-codex.mjs";
        WorkingDirectory = config.home.homeDirectory;
        Environment = environment;
        UMask = "0077";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
