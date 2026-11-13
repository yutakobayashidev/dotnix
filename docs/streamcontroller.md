# StreamController on X870

X870 enables `my.programs.streamcontroller.enable`. The feature imports
`Daaboulex/streamcontroller-nix`, installs its native package and USB access rules,
and enables its XDG autostart entry. Its Home Manager module is enabled for the
host's users. Other hosts leave the feature disabled.

Apply the configuration on X870 with `nix run .#switch`. Log in again for
autostart, or launch `streamcontroller` from the launcher or terminal. Reconnect
the Stream Deck if an existing connection has not picked up the new USB rules.

## Pages and plugins

The native application stores data in `~/.local/share/StreamController`.
Install plugins through its plugin store; the upstream Nix module does not
declare or pin plugins. No initial page or device serial is guessed by dotnix.

Declare pages inside `home-manager.users.${username}` in
`homes/nixos/X870-Steel-Legend-WiFi/default.nix`. For example, after installing
the OS plugin, this creates a microphone mute button:

```nix
programs.streamcontroller.pages.Main.keys."0x0".states."0" = {
  label.center.text = "Mute";
  actions = [
    {
      id = "com_core447_OSPlugin::RunCommand";
      settings.command =
        "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
    }
  ];
};
```

Select the page in the application. Once the real device serial is known,
`programs.streamcontroller.defaultPages."SERIAL" = "Main"` declares its default.
Existing page JSON can instead be supplied through `pageFiles`.

Activation copies declared pages into writable files, overwriting GUI edits to
those pages. Removing a declaration does not delete its old deployed page; remove
that page separately in the application. Restart the application after changing
declarative pages. Keep a backup before handing GUI-created pages to Nix.

Plugin environments remain mutable. The upstream activation hook attempts to
repair broken Python environments and may download dependencies with pip, so
the plugin installation is not reproduced solely by `flake.lock`.

Niri-specific input simulation and automatic page switching need hardware/session
verification. Command actions such as `wpctl` avoid keyboard simulation.

See the [upstream module documentation](https://github.com/Daaboulex/streamcontroller-nix).
