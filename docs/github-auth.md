# GitHub authentication

GitHub CLI manages local GitHub authentication with expiring, automatically
refreshed OAuth credentials. Home Manager sets
`programs.gh.settings.expiring_credentials = "enabled"`, so `gh auth login`
requests them by default. HTTPS Git authentication uses Home Manager's
`programs.gh.gitCredentialHelper` integration for GitHub and Gist.

This requires gh 2.103.0 or later. The overlay pins gh 2.103.2 until the
repository's nixpkgs pin supplies a supported version. See the
[official announcement](https://github.blog/changelog/2026-10-21-github-cli-opt-in-to-expiring-auto-refreshing-oauth-tokens/).

## Initial login and migration

Apply the configuration with `nix run .#switch`, then start a fresh shell to
drop the previous 1Password gh alias and old session environment. Log in:

```bash
gh auth login --hostname github.com --web --git-protocol https
gh auth status --hostname github.com
```

The default applies to new sign-ins; it does not convert existing credentials.
Run the login command again when migrating from previous authentication.
Authentication requires completing the browser authorization flow. Confirm
that `gh auth status` reports a refreshable credential and its expiration.
The configuration already supplies Git's helper, so `gh auth setup-git` is
unnecessary.

The former token wrapper, agent service, and `ghauth` shell function are
removed. Existing credentials in the old backend are not migrated or revoked;
after verifying the new login, revoke unused authorizations in GitHub settings.
The 1Password shell plugins remain enabled for awscli2 and tea only.

## Verification and daily use

```bash
gh --version
gh config get expiring_credentials
git config --get-all credential.https://github.com.helper
gh api user --jq .login
git ls-remote https://github.com/OWNER/PRIVATE-REPOSITORY.git HEAD
```

The setting should be `enabled`, and the helper should end in
`/bin/gh auth git-credential` after an empty entry that clears earlier helpers.
Use an accessible private repository for the last check to exercise authentication.
Git 2.46 or later is recommended to avoid caching expired credentials.

GitHub CLI refreshes its stored credentials as needed. Explicit `GH_TOKEN` or
`GITHUB_TOKEN` values override stored credentials and are not refreshed; unset
them in interactive shells when using this setup. Tools consuming a token
outside gh should call `gh auth token` each time instead of caching its output.
Hosts that do not support expiring credentials may issue non-expiring tokens.
