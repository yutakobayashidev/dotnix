# Orca headless server

UM790-Pro runs `pkgs.llm-agents.orca` as the `yuta` user through the Home Manager
service in `homes/nixos/UM790-Pro/orca.nix`. The existing NixOS user linger setting
starts it at boot and keeps it running after logout. This uses the community Nix
package; upstream Orca does not currently provide a NixOS service module.

Orca 1.4.224 is missing the packaged Node runtime selection entrypoint, so this
service selects the officially supported `ORCA_SERVE_RUNTIME=electron` mode.
It uses a dedicated Xvfb display and clears desktop display variables so it does
not depend on a logged-in GUI.
With startup diagnostics disabled, this packaged version did not publish its
readiness or pairing output on UM790-Pro. `ORCA_STARTUP_DIAGNOSTICS=1` is retained:
with it enabled, startup completed and a connection using the pairing URL
succeeded. The underlying cause is not yet established; recheck when upgrading.

The server advertises `um790-pro.tail29d068.ts.net:6768`. Connect over Tailscale;
the existing firewall trusts `tailscale0`. `--pairing-address` advertises an
address to clients and does not restrict the server's listening interface.

```bash
systemctl --user status orca
journalctl --user -u orca -b
# Show the latest connection link locally (do not share it publicly).
journalctl --user -u orca -b -o cat | rg '^Pairing URL:' | tail -1
```

Copy the pairing URL from the journal into the client application's
Settings → Remote Orca Servers → Add Server. Treat the URL as a credential.
Do not run a second Orca desktop host against the same user data while this
service is running. Agents use the server user's installed CLIs and credentials.
If managed accounts need registration, run `orca account add --agent codex` or
`orca account add --agent claude` on UM790-Pro.

See the [official Remote Orca Servers guide](https://www.onorca.dev/docs/remote-servers).

## Initial deployment

The initial Home Manager activation was blocked by an existing non-managed
`~/.config/claude/skills` directory. Only the generated Orca unit and its
`default.target.wants` link were installed from the built Home Manager generation;
the generation is retained by `~/.local/state/nix/gcroots/orca-home`.
The service is enabled and running. After resolving that skills-directory
conflict and completing a normal rebuild, the temporary GC root can be removed.
