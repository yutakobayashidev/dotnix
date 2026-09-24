# Beeper Server on UM790-Pro

The CLI is installed only on UM790-Pro. The headless Server is pinned in
`nur-packages/pkgs/beeper-server` and managed by the Home Manager user service
`beeper-server`. It listens only on `127.0.0.1:23373`; no firewall port is opened.
Do not run `setup --server --install` or `targets enable`: Nix manages the binary
and systemd service, not the CLI installer.

## Initial deployment

The new `beeper-server` package must first be published in nur-packages and the
dotnix input updated. Until then, test with
`--override-input nur-packages path:../nur-packages` from dotnix.
UM790's user must have linger enabled for operation without a GUI login.

## One-time login

On UM790 in an interactive terminal:

```sh
beeper-cli setup --remote http://127.0.0.1:23373 --target um790 --email YOUR_EMAIL
beeper-cli status --target um790 --json
beeper-cli chats list --target um790 --limit 1
```

Complete email/device verification in the terminal, never in chat or Nix files.
Do not create a new account unintentionally if the login flow offers registration.
The CLI target is `remote` to avoid managing the already-running systemd process.
Server data lives in `~/.local/state/beeper-server` (0700). CLI credentials live
under `~/.beeper` by default. Preserve both on persistent storage and in protected
backups; never put either in the Nix store or a temporary directory.

```sh
systemctl --user status beeper-server
journalctl --user -u beeper-server
systemctl --user restart beeper-server
```

The initial test uses a transient systemd unit; it is not a reboot-persistent
deployment. Apply the Home Manager service after publishing the package.
Before applying it, stop the transient unit and reload the user manager.

The binary is a nightly distribution; check actual chat retrieval, not only
process health, before adding an MCP adapter. The shared Desktop MCP configuration
is unchanged and does not constitute a verified Server MCP deployment.
