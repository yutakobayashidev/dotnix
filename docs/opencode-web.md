# OpenCode Web

After applying the configuration on both hosts, open
<https://opencode.home.yutakobayashi.com/> from the Tailnet and sign in as
`opencode`.

UM790-Pro runs the Home Manager `opencode-web.service` on its Tailscale address
`100.91.91.87:4096`. B450M-Pro4 terminates HTTPS with Traefik and allows only
Tailnet source addresses, as for [dsh Web](dsh-web.md). Existing wildcard DNS
covers the hostname. The service uses the same OpenCode package, configuration,
provider credentials, and session storage as the user's CLI, with the home
directory as its working directory. User lingering starts it without login;
failed starts are retried after five seconds.

## Password

The [upstream authentication mechanism](https://opencode.ai/docs/web/#authentication)
uses `OPENCODE_SERVER_PASSWORD` and defaults to the username `opencode`.
The generated password is encrypted in `secrets/opencode-web.yaml` for the
UM790-Pro and ThinkPad Home Manager age keys. No plaintext password is stored
in the repository or Nix store. sops-nix renders the runtime environment file
with mode `0400`; the service refuses to start with an empty password.

To retrieve the password on UM790-Pro after activation:

```bash
cat ~/.config/sops-nix/secrets/opencode-web-password
```

Alternatively, decrypt the encrypted source on either recipient host:

```bash
nix shell nixpkgs#sops -c sops decrypt --extract '["password"]' secrets/opencode-web.yaml
```

The age identity is `~/.config/sops/age/keys.txt` on each recipient host.
Recovery requires the encrypted file and either recipient's existing identity.
Never copy the identity or plaintext password into `/tmp` or the repository.
To rotate the password, edit the encrypted file with sops, apply Home Manager,
and restart `opencode-web` so it reads the updated environment file. Use a
single-line hexadecimal password so it is safe in systemd's environment format.

## Verification

On UM790-Pro:

```bash
systemctl --user status sops-nix opencode-web
journalctl --user -u opencode-web -b -n 50
```

From a Tailnet client, the health API must reject unauthenticated requests and
accept the configured password. The second command prompts for the password
without including it in the command line:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://opencode.home.yutakobayashi.com/global/health
curl --user opencode https://opencode.home.yutakobayashi.com/global/health
```

Expect `401` without credentials and a healthy JSON response after signing in.
Also open the HTTPS URL in a browser and verify that the project/session UI loads.

Configuration lives in `modules/features/super-intelligence/opencode/default.nix`,
`homes/nixos/UM790-Pro/opencode.nix`, and
`systems/nixos/services/opencode-web/default.nix`.

## Deployment

Commit the Nix modules, encrypted password, and `.sops.yaml` recipient rule
together. Both hosts follow `main` through Comin. Home Manager installs and
enables the user service; sops-nix decrypts the password at activation/startup;
NixOS installs the Traefik route. No manually maintained service overrides or
proxy configuration files are required, including after a host reboot.

Verify both hosts have deployed the commit before checking the HTTPS endpoint.
For a manual deployment from a clean checkout, run `nix run .#switch` on each
host. Do not apply unrelated local worktree edits as part of an OpenCode update.
