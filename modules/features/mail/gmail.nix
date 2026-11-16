# Adapted from natsukium/dotfiles homes/shared/email.nix (CC0).
_: {
  flake.modules.homeManager.gmail =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.gmail;
      isync = pkgs.isync.override { withCyrusSaslXoauth2 = true; };
      postSync = pkgs.writeShellScript "mail-index" ''
        set -eu
        export PATH=${
          lib.makeBinPath [
            pkgs.notmuch
            pkgs.coreutils
          ]
        }:$PATH
        ${lib.getExe pkgs.notmuch} new
        ${lib.getExe pkgs.afew} --tag --new
        ${lib.getExe pkgs.afew} --move-mails
      '';
    in
    {
      options.my.programs.gmail = {
        enable = lib.mkEnableOption "Gmail synchronization, indexing and tagging";
        address = lib.mkOption {
          type = lib.types.str;
          description = "Gmail account address.";
        };
        realName = lib.mkOption {
          type = lib.types.str;
          default = "Yuta Kobayashi";
        };
        sopsFile = lib.mkOption {
          type = lib.types.path;
          description = "SOPS YAML with gmail-oauth-client-id and gmail-oauth-client-secret.";
        };
      };
      config = lib.mkIf cfg.enable {
        accounts.email.maildirBasePath = "Mail";
        accounts.email.accounts.gmail = {
          primary = true;
          address = cfg.address;
          realName = cfg.realName;
          flavor = "gmail.com";
          passwordCommand = "${lib.getExe config.my.services.pizauth.package} show gmail";
          mbsync = {
            enable = true;
            create = "maildir";
            remove = "maildir";
            expunge = "both";
            extraConfig.account.AuthMechs = "XOAUTH2";
          };
          notmuch.enable = true;
          folders.inbox = "Inbox";
        };
        programs.mbsync = {
          enable = true;
          package = isync;
        };
        my.services.mbsync = {
          enable = true;
          package = isync;
          postExec = "${postSync}";
        };
        systemd.user.services.mbsync.Unit = {
          After = [ "pizauth.service" ];
          Requires = [ "pizauth.service" ];
        };
        programs.notmuch = {
          enable = true;
          settings.new.tags = [
            "new"
            "unread"
          ];
        };
        programs.afew = {
          enable = true;
          extraConfig = ''
            [HeaderMatchingFilter.0]
            header = From
            pattern = notifications@github.com
            tags = +github

            [HeaderMatchingFilter.1]
            header = X-GitHub-Reason
            pattern = review_requested|mention
            tags = +github::action-required

            [Filter.0]
            query = tag:github
            tags = -new

            [InboxFilter]

            [MailMover]
            folders = gmail/Inbox "gmail/[Gmail]/All Mail" "gmail/[Gmail]/Sent Mail" gmail/[Gmail]/Drafts gmail/[Gmail]/Starred
            rename = true
            gmail/Inbox = 'tag:deleted':'gmail/[Gmail]/Trash' 'NOT tag:inbox':'gmail/[Gmail]/All Mail'
            gmail/[Gmail]/All Mail = 'tag:deleted':'gmail/[Gmail]/Trash'
            gmail/[Gmail]/Sent Mail = 'tag:deleted':'gmail/[Gmail]/Trash'
            gmail/[Gmail]/Drafts = 'tag:deleted':'gmail/[Gmail]/Trash'
            gmail/[Gmail]/Starred = 'tag:deleted':'gmail/[Gmail]/Trash'
          '';
        };
        my.services.pizauth = {
          enable = true;
          persistence = {
            enable = true;
            ageIdentity = config.sops.age.keyFile;
            ageRecipient = "${config.xdg.configHome}/pizauth/recipient.txt";
          };
          accounts.gmail = {
            authUri = "https://accounts.google.com/o/oauth2/auth";
            tokenUri = "https://oauth2.googleapis.com/token";
            clientIdSecret = "gmail-oauth-client-id";
            clientSecretSecret = "gmail-oauth-client-secret";
            scopes = [ "https://mail.google.com/" ];
            authUriFields = {
              login_hint = cfg.address;
              access_type = "offline";
            };
          };
        };
        home.activation.pizauthRecipient = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/pizauth"}
          run ${pkgs.bash}/bin/bash -c ${lib.escapeShellArg "${lib.getExe' pkgs.age "age-keygen"} -y ${lib.escapeShellArg config.sops.age.keyFile} > ${lib.escapeShellArg "${config.xdg.configHome}/pizauth/recipient.txt"}"}
        '';
        sops.secrets.gmail-oauth-client-id.sopsFile = cfg.sopsFile;
        sops.secrets.gmail-oauth-client-secret.sopsFile = cfg.sopsFile;
      };
    };
}
