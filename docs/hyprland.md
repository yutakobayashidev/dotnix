# Hyprland desktop session

Niri remains the default desktop. UM790-Pro and X870-Steel-Legend-WiFi also
provide Hyprland in ReGreet's session selector. Choose Hyprland before logging
in to try it; select Niri to return. No running session is switched by this
configuration change. ReGreet may remember the session you last selected.

The ThinkPad laptop and headless B450M-Pro4 do not enable Hyprland. The shared
NixOS desktop configuration enables `my.programs.hyprland` only when the
laptop profile is disabled; the feature then enables its Home Manager half.

## Restored configuration

Commit `8ff406a4` migrated to Niri, and `d138e660` removed the old Hyprland
files. The restored configuration takes its dwindle layout, gaps, rounded
windows, workspace shortcuts, scratchpad, mouse movement and screenshots
from those files. It uses the current Catppuccin Mocha palette, Noctalia,
Vicinae, Nautilus, swayidle and swaylock instead of restoring Hyprpanel,
Rofi and the old wallpaper daemon.

The pinned Hyprland 0.56 uses Lua. Home Manager generates
`~/.config/hypr/hyprland.lua` from
`modules/features/window-manager/hyprland/settings.nix`; the historical
hyprlang configuration is not copied verbatim. Home Manager starts the
Hyprland graphical session target so shared desktop services can run.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Super+Q | Ghostty |
| Super+E | Nautilus |
| Super+R | Vicinae |
| Super+V | Clipboard history |
| Super+C | Close window |
| Super+L | Lock session |
| Super+Shift+M | Exit Hyprland |
| Super+Shift+F | Toggle floating |
| Super+J | Toggle dwindle split |
| Super+arrow | Focus window |
| Super+1…0 | Switch workspace 1…10 |
| Super+Shift+1…0 | Move window to workspace 1…10 |
| Super+S | Toggle scratchpad |
| Super+Ctrl+S | Move window to scratchpad |
| Super+left/right mouse drag | Move/resize window |
| Super+] | Copy output screenshot |
| Super+Shift+] | Copy active window screenshot |
| Super+Shift+S | Copy selected area screenshot |

## Verification

Evaluate both system and Home Manager enable flags for the two desktops,
the ThinkPad and B450M-Pro4 before rollout. Validate the generated Lua with
the pinned compositor's `Hyprland --verify-config -c <generated-file>`.
A successful configuration check does not replace a real login test for
monitor layout, IME, screen sharing and locking.
