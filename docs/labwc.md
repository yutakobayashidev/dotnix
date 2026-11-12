# labwc desktop session

Niri remains the default desktop. All graphical NixOS hosts (UM790-Pro,
X870-Steel-Legend-WiFi and ThinkPad-X1-Carbon-Gen13) also provide labwc in
ReGreet's session selector. After applying the configuration, log out and
select labwc before logging in. ReGreet may remember the last selection.
The headless B450M-Pro4 and macOS do not enable this feature.

The configuration follows the [reference commit](https://github.com/akazdayo/nix-configs/commit/4ca95b2fbd8bdcba7b4c9006e465800df13b4b39):
four workspaces, default mouse bindings, session-scoped Fcitx5 and polkit,
and the wlr portal for screen capture. Home Manager manages the labwc session
target, which starts the existing graphical-session services such as Noctalia,
Vicinae and swayidle. The shutdown script stops the graphical target before
the compositor closes its Wayland socket.

## Shortcuts

| Shortcut                       | Action                                  |
| ------------------------------ | --------------------------------------- |
| Super+Return / Super+Q         | Ghostty                                 |
| Super+E                        | Nautilus                                |
| Super+D / Super+V              | Vicinae / clipboard history             |
| Super+Space / Super+Ctrl+Space | Handy recording / transcription         |
| Super+C / Super+F              | Close / maximize window                 |
| Super+L                        | Lock session                            |
| Super+1…4 / Super+Shift+1…4    | Switch workspace / move window          |
| Super+S / Super+comma          | Noctalia control center / settings      |
| Super+Escape / Super+Shift+E   | Session panel / exit labwc              |
| Volume and brightness keys     | Noctalia volume and brightness controls |

## Output configuration

Set `my.programs.labwc.outputModes` in a host's Home Manager configuration
when a specific mode is needed. Output names can be listed with `wlr-randr`.
The default leaves output modes to the compositor; the reference host's
monitor-specific refresh rate is not applied globally.

```nix
my.programs.labwc.outputModes."DP-1" = "1920x1080@144Hz";
```

Additional startup commands, such as `wlr-randr` scale settings, can be added
through `wayland.windowManager.labwc.autostart`.

## Verification

Evaluate system and Home Manager flags for all four NixOS hosts and the
affected system derivations before rollout. After logging in, check Noctalia,
Vicinae, Japanese input, screen sharing, monitor scaling, and lock/unlock.
After logout, `labwc-session.target` and its Fcitx5/polkit services should
be inactive. Nix evaluation does not verify these interactive behaviors.
