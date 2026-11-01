# Agent Desktop

The desktop profile installs `agent-desktop` from `nur-packages` on Linux and enables the NixOS AT-SPI accessibility bus. The Home Manager toggle is `my.programs.agent-desktop.enable`; macOS and headless profiles do not enable it by default. The package is built from the tagged upstream Rust source and includes the Linux clipboard-owner helper and `wl-clipboard` runtime dependency.

After deploying the configuration, log out and back in so applications inherit the accessibility settings. Run these commands inside the graphical user session:

```sh
agent-desktop version
agent-desktop skills get desktop
agent-desktop skills get platform
agent-desktop status
agent-desktop list-apps
```

Read the built-in guides before using the tool to operate applications. For an app returned by `list-apps`, use `agent-desktop snapshot --app <name> -i` to inspect its accessibility tree. Applications must expose accessibility information; an SSH or TTY session alone does not provide desktop access.

On Niri and other Wayland compositors, semantic AT-SPI actions are available, but physical pointer input and native window control are unsupported. Wayland keyboard input requires GNOME Mutter; notification operations require GNOME Shell. Screenshots use a desktop portal. This package does not provide those GNOME-specific capabilities on Niri.

The feature module is `modules/features/super-intelligence/agent-desktop/default.nix`; profile defaults are in `modules/profiles/desktop.nix`. See the [upstream installation guide](https://github.com/vercel-labs/agent-desktop/blob/v1.0.2/docs/install.md) for platform details.
