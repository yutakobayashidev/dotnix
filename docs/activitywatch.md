# ActivityWatch on ThinkPad

Only `ThinkPad-X1-Carbon-Gen13` enables `my.services.activitywatch.enable`.
Home Manager runs the local ActivityWatch server and
`aw-watcher-window-wayland` with the graphical session. The Wayland watcher
records the active application/window title and AFK state on Niri; the standard
X11 window and AFK watchers are not started.

The server listens on `127.0.0.1:5600`. Open the ActivityWatch launcher entry or
<http://127.0.0.1:5600>. Data stays on the ThinkPad; no Android sync or remote
collector is configured. The pinned nixpkgs currently supplies ActivityWatch
0.13.2, so do not assume the newer Android/desktop 0.14 sync setup is available.

## Browser recording

Firefox policy installs ActivityWatch Web Watcher from Mozilla Add-ons, with
Mozilla-managed updates. It is removable/disableable by the user. Restart Firefox
after activation and check the extension is enabled. It records active-tab URLs
and titles, which add context beyond the window title. Do not grant private-window
access unless you intend to record those sessions. Other browsers are not configured.

## Apply and verify

On the ThinkPad, from the dotnix checkout containing these changes:

```sh
nix run .#switch
systemctl --user status activitywatch.target activitywatch.service activitywatch-watcher-aw-watcher-window-wayland.service
journalctl --user -u activitywatch-watcher-aw-watcher-window-wayland.service -n 50
curl --fail http://127.0.0.1:5600/api/0/buckets/
```

If the current graphical session has not started the newly installed target, run
`systemctl --user start activitywatch.target` once, or log out and back in.
Switch between two applications and Firefox tabs, then check that window, AFK,
and browser buckets receive events. Leave the computer idle long enough to verify
an AFK transition. A running unit alone does not prove recording works.

Use the web UI's bucket export before experimenting with data migration. The
server normally stores data under `~/.local/share/activitywatch/aw-server-rust/`.
Stop the target before taking a filesystem-level database backup.

To pause collection, run `systemctl --user stop activitywatch.target`.
Run `systemctl --user start activitywatch.target` to resume. Disable the host's
feature flag and rebuild to stop automatic startup permanently; saved data is
not deleted.

## Sources

- [Home Manager module](https://github.com/nix-community/home-manager/blob/master/modules/services/activitywatch.nix)
- [Wayland watcher compatibility](https://github.com/ActivityWatch/aw-watcher-window-wayland)
- [Web watcher](https://github.com/ActivityWatch/aw-watcher-web)
