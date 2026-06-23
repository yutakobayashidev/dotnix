# Secure GitHub Authentication with ghtkn

This repository uses `ghtkn` for local GitHub authentication instead of
long-lived Personal Access Tokens.

The setup separates:

- GitHub API access through `gh`
- Git push and pull authentication through Git's credential helper
- GitHub App selection through directory-specific `direnv` environments

The Nix configuration in this repository is the source of truth. Do not
configure the `gh` wrapper or Git credential helper manually in generated
files under `$HOME`.

## Architecture

The local authentication flow is:

```txt
gh
└── Nix-managed wrapper
    └── ghtkn get
        └── short-lived GitHub App User Access Token

git push / git pull
└── Git credential helper
    └── ghtkn git-credential
        └── short-lived GitHub App User Access Token

direnv
└── selects the API and Git Apps for the current directory
```

Tokens are stored by `ghtkn` in the operating system's secret manager, such as
macOS Keychain or GNOME Keyring. The repository does not store generated
tokens, GitHub App private keys, or client secrets.

## GitHub App Layout

Use separate GitHub Apps by purpose:

```txt
yutakobayashidev/none   - safe default with no write permissions
yutakobayashidev/write  - GitHub API operations
yutakobayashidev/git    - Git push and pull
```

### `yutakobayashidev/none`

Use this as the safe default.

Recommended permissions:

```txt
No repository write permissions
```

This App is suitable for public repository reads and authenticated API rate
limits.

### `yutakobayashidev/write`

Use this for GitHub API operations such as:

```sh
gh pr create
gh pr edit
gh issue create
```

Recommended permissions:

```txt
pull-requests:write
issues:write
metadata:read
```

Optional read permissions:

```txt
contents:read
actions:read
checks:read
```

Do not grant `contents:write` or `workflows:write` unless they are required.
The API App should not normally be able to push repository contents.

### `yutakobayashidev/git`

Use this only for Git operations.

Recommended permissions:

```txt
contents:write
workflows:write
metadata:read
```

`workflows:write` is required when pushing changes under
`.github/workflows/`.

## ghtkn Configuration

`ghtkn` reads its configuration from:

```txt
${XDG_CONFIG_HOME:-$HOME/.config}/ghtkn/ghtkn.yaml
```

Example:

```yaml
apps:
  - name: yutakobayashidev/none
    client_id: xxx

  - name: yutakobayashidev/write
    client_id: yyy

  - name: yutakobayashidev/git
    client_id: zzz
    git_owner: yutakobayashidev
```

The Client IDs are not secrets. Do not add generated access tokens or GitHub
App private keys to this repository.

The `name` field is local to `ghtkn`. This repository uses:

```txt
<app-owner>/<purpose>
```

## GitHub CLI

The GitHub CLI configuration is defined in:

```txt
applications/gh/default.nix
```

Home Manager installs:

- `gh`
- `ghtkn`
- the configured `gh` extensions
- a high-priority `gh` wrapper

The wrapper behaves as follows:

```sh
if [ -z "${GH_TOKEN:-}" ] && [ -z "${GITHUB_TOKEN:-}" ]; then
  GH_TOKEN="$(ghtkn get)"
  export GH_TOKEN
fi

exec <nix-store-gh> "$@"
```

The real `gh` and `ghtkn` executables are referenced with Nix store paths.
This avoids recursive wrapper calls.

An existing `GH_TOKEN` or `GITHUB_TOKEN` is respected. Otherwise, the wrapper
requests a short-lived token from `ghtkn`.

Home Manager's built-in `gh` Git credential helper is explicitly disabled:

```nix
programs.gh.gitCredentialHelper.enable = false;
```

Git authentication is handled separately by `ghtkn`.

## Git Credential Helper

Git configuration is defined in:

```txt
applications/git/default.nix
```

The effective configuration is equivalent to:

```ini
[credential "https://github.com"]
	helper =
	helper = !/nix/store/...-ghtkn/bin/ghtkn git-credential
	useHttpPath = true
```

The empty helper entry resets lower-priority credential helpers for GitHub
only. Non-GitHub remotes keep the normal Git credential lookup path.

`useHttpPath = true` ensures that `ghtkn` receives the repository path as well
as the hostname. This is required for owner-based App selection.

Do not edit `~/.gitconfig` manually. Home Manager generates it from
`applications/git/default.nix`.

## App Selection

`ghtkn` supports two mechanisms for selecting the Git App.

### `git_owner`

`git_owner` is configured in `ghtkn.yaml`:

```yaml
apps:
  - name: yutakobayashidev/git
    client_id: zzz
    git_owner: yutakobayashidev
```

This selects `yutakobayashidev/git` when Git accesses:

```txt
https://github.com/yutakobayashidev/...
```

### `GHTKN_GIT_APP`

`GHTKN_GIT_APP` is an explicit fallback or override:

```sh
export GHTKN_GIT_APP=yutakobayashidev/git
```

This is useful for pull request branches from forks whose repository owner
does not match `git_owner`.

Use both `git_owner` and `GHTKN_GIT_APP`:

- `git_owner` provides URL-based selection.
- `GHTKN_GIT_APP` handles forks and explicit overrides.

## Directory-Based Selection with direnv

The repository `.envrc` contains:

```sh
source_up
use flake
```

`source_up` loads the nearest parent `.envrc` before entering the repository's
Nix development shell.

A practical directory layout is:

```txt
~/ghq/github.com/.envrc
~/ghq/github.com/yutakobayashidev/.envrc
~/ghq/github.com/yutakobayashidev/dotnix/.envrc
```

Configure the owner-level environment outside this repository:

```sh
# ~/ghq/github.com/yutakobayashidev/.envrc
source_up

export GHTKN_APP=yutakobayashidev/write
export GHTKN_GIT_APP=yutakobayashidev/git
```

The repository inherits these variables through `source_up`.

For long-running operations, the repository `.envrc` may additionally set:

```sh
export GHTKN_MIN_EXPIRATION=30m
```

After changing an `.envrc`, authorize it:

```sh
direnv allow
```

### Environment Variable Roles

```txt
GHTKN_APP      - App used by `ghtkn get` and therefore the `gh` wrapper
GHTKN_GIT_APP  - App used by `ghtkn git-credential`
git_owner      - URL-based Git App selection from ghtkn.yaml
source_up      - parent direnv environment inheritance
```

## Applying the Configuration

Apply the current host configuration:

```sh
nix run .#switch
```

This runs:

- `darwin-rebuild switch` on macOS
- `nixos-rebuild switch` on NixOS

Build without applying:

```sh
nix run .#build
```

After switching, open a new shell or reload the environment so that the
Home Manager package path and generated Git configuration are current.

## Verification

### Verify the Git credential helper

```sh
git config --global --get credential.https://github.com.helper
git config --global --get credential.https://github.com.useHttpPath
```

Expected output:

```txt

!/nix/store/...-ghtkn/bin/ghtkn git-credential
true
```

The first output line is intentionally empty.

### Verify the gh wrapper

```sh
type -a gh
gh --version
gh auth status
```

The first `gh` in `PATH` should be the Home Manager wrapper.

### Verify direnv selection

```sh
echo "$GHTKN_APP"
echo "$GHTKN_GIT_APP"
```

Inside this repository, the expected values are:

```txt
yutakobayashidev/write
yutakobayashidev/git
```

### Verify Git operations

```sh
git fetch
git push --dry-run
```

These commands should invoke `ghtkn git-credential` without requiring a
Personal Access Token.

## Token Expiration

`ghtkn` stores tokens and expiration metadata in the configured backend.
Desktop machines use the OS secret manager. `B450M-Pro4` uses the `agent`
backend because it has no desktop keyring service; its Home Manager
configuration is in `homes/nixos/B450M-Pro4/ghtkn-agent.nix`.

After the agent starts or restarts, unlock it once:

```sh
ghtkn agent unlock
```

`ghtkn get` reuses a token while it has sufficient remaining lifetime.

Require a minimum remaining lifetime for a single command:

```sh
ghtkn get -m 1h
```

Or configure it through direnv:

```sh
export GHTKN_MIN_EXPIRATION=30m
```

## Company Organizations

For a company organization, create shared organization-level Apps instead of
one App per developer:

```yaml
apps:
  - name: company/none
    client_id: xxx

  - name: company/write
    client_id: yyy

  - name: company/git
    client_id: zzz
    git_owner: company
```

Developers share Client IDs, but each Device Flow produces a User Access Token
for the user who approved it.

Effective access is the intersection of:

```txt
The user's permissions
∩ The GitHub App's permissions
∩ The repositories where the App is installed
```

A user cannot gain repository access merely because the App has
`contents:write`.

## Operational Rules

```txt
Do not use Personal Access Tokens for local development.
Do not store access tokens or GitHub App private keys in this repository.
Manage gh and Git credential settings through Nix, not generated files.
Use GHTKN_APP for GitHub API operations.
Use GHTKN_GIT_APP for Git push and pull.
Keep contents:write and workflows:write on the Git App only.
Use source_up to inherit owner-level direnv settings.
Do not wrap broad task runners with GH_TOKEN.
```

## Relevant Files

```txt
applications/gh/default.nix    - gh wrapper, ghtkn package, gh extensions
applications/git/default.nix   - ghtkn Git credential helper
.envrc                         - parent direnv inheritance and Nix dev shell
docs/ghtkn.md                  - this document
```
