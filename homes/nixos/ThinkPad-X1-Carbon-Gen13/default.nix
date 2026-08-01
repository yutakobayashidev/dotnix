{ inputs, username, ... }:

{
  imports = [ ../common.nix ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [
        ../../desktop.nix
        ../../../applications/course-cli
        ../desktop.nix
        inputs.openbrief.homeManagerModules.default
        inputs.onepassword-shell-plugins.hmModules.default
        inputs.temari.homeManagerModules.default
      ];
      home.homeDirectory = "/home/${username}";
      home.packages = with pkgs; [
        alcom
        beatoraja
        blender
        nordvpn.cli
        osu-lazer-bin
        tetrio-desktop
        unityhub
        vrc-get
        vrcx
      ];
      my.programs.mcp.ghidra.enable = true;
      services = {
        openbrief.enable = true;
        poweralertd.enable = true;
        temari = {
          enable = true;
          workspaces.downloads = {
            workspaceId = "workspace-1785071330865-1131974-0";
            configFile = "/home/yuta/.config/temari/config.toml";
            stateFile = "/home/yuta/.local/state/temari/managed.sqlite3";
            source = "/home/yuta/Downloads";
            interval = "1h";
          };
        };
        wallpaper.imagePath = "/home/${username}/wallpapers/lycoris-recoil-rain.jpg";
      };
      programs = {
        _1password-shell-plugins = {
          enable = true;
          plugins = with pkgs; [
            gh
            awscli2
            tea
          ];
        };
        firefox.profiles.nix.settings."security.enterprise_roots.enabled" = true;
      };
      programs.niri.settings.input.touchpad = {
        accel-speed = -0.2;
        natural-scroll = true;
      };
      programs.niri.settings.binds = {
        "Ctrl+J" = {
          repeat = false;
          action.spawn = [
            "${pkgs.bash}/bin/bash"
            "-c"
            ''
              selected_text="$(${pkgs.wl-clipboard}/bin/wl-paste --primary --no-newline)" || exit 0
              [ -n "$selected_text" ] || exit 0
              encoded_text="$(printf '%s' "$selected_text" | ${pkgs.jq}/bin/jq -sRr @uri)"
              exec ${pkgs.xdg-utils}/bin/xdg-open "naniapp://translate?source=$encoded_text"
            ''
          ];
        };
        "Mod+Ctrl+J" = {
          repeat = false;
          action.spawn = [
            "${pkgs.xdg-utils}/bin/xdg-open"
            "naniapp://translate"
          ];
        };
      };
      xdg.mimeApps.defaultApplications."x-scheme-handler/naniapp" = "nani.desktop";
    };
}
