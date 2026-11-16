# Gmail synchronization and local search

The shared Home Manager modules under `modules/features/mail/` adapt
[natsukium/dotfiles](https://github.com/natsukium/dotfiles/tree/cff1479cc31b5cdb06c61843a3e3df7a01725846/modules/features/mail).
They connect pizauth OAuth tokens, XOAUTH2 mbsync, notmuch and afew.
The upstream `mail` skill is pinned separately in the source registry, replacing
`audit-email-noise`. The local skills checkout deletes the retired skill; it is
also excluded from discovery until that deletion is published and pinned.

## Initial setup

OAuth credentials and the account address are not configured yet. Synchronization
stays disabled until they are supplied. First validate on ThinkPad; UM790-Pro can
use the same module and OAuth client, with its own authorization and token dump.

1. In Google Cloud, enable Gmail API, configure the OAuth consent screen and create
   a **Desktop app** OAuth client with the `https://mail.google.com/` scope.
   Store its downloaded JSON in a private persistent directory with mode 0600.
   For an external app in Testing, add your account as a test user; refresh tokens
   with Gmail scopes expire after seven days in Testing (see
   [Google OAuth documentation](https://developers.google.com/identity/protocols/oauth2)).
2. Create `secrets/gmail.yaml` using SOPS with keys `gmail-oauth-client-id` and
   `gmail-oauth-client-secret`. Never put plaintext credentials in the repository,
   Nix expressions, the store, or temporary files.
3. Add this to the target host's `home-manager.users.${username}` configuration,
   substituting the actual Gmail account address:

   ```nix
   my.programs.gmail = {
     enable = true;
     address = "your-address@gmail.com";
     sopsFile = ../../../secrets/gmail.yaml;
   };
   ```

4. Set Gmail's display language to English (US), matching the `[Gmail]/All Mail`,
   `[Gmail]/Trash`, and other folder names used by the upstream MailMover rules.
   Apply the host configuration, run `pizauth show gmail`, and follow the URL
   reported by `pizauth status` to authorize that host.
5. Run `systemctl --user start mbsync`, then check
   `journalctl --user -u pizauth -u mbsync -n 80`, `notmuch count '*'`, and
   `notmuch search --limit=10 tag:github`. Check the filters without modifying mail
   using `afew --tag --new --dry-run -vv`.

The periodic mbsync service runs notmuch and afew after successful sync. GitHub
notifications receive `github` and, for mentions/reviews, `github::action-required`;
they are archived by the upstream rules. Removing `inbox` archives a message;
adding `deleted` moves it to Trash. These folder changes and standard flags reach
Gmail on the following sync. Other notmuch tags remain local.

Each host keeps its own `~/Mail` and notmuch database. Do not file-sync those
between hosts. Authorize each host separately. Tokens persist encrypted at
`~/.local/share/pizauth/dump.age` using the existing Home Manager SOPS age identity;
the public recipient is generated at `~/.config/pizauth/recipient.txt`. Retain the
age identity through the existing SOPS recovery process; if the dump or key is
lost, reauthorize Gmail. Never copy the identity into this repository.
