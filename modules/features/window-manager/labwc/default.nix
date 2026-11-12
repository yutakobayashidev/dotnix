_:

{
  flake.modules.nixos.labwc =
    {
      config,
      lib,
      pkgs,
      options,
      ...
    }:
    {
      options.my.programs.labwc.enable = lib.mkEnableOption "labwc desktop session";

      config = lib.mkIf config.my.programs.labwc.enable (
        {
          programs.labwc.enable = true;
          xdg.portal = {
            extraPortals = [
              pkgs.xdg-desktop-portal-wlr
              pkgs.xdg-desktop-portal-gtk
            ];
            config.labwc = {
              default = [ "gtk" ];
              "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
              "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
            };
          };
        }
        // lib.optionalAttrs (lib.hasAttrByPath [ "home-manager" "sharedModules" ] options) {
          home-manager.sharedModules = [
            { my.programs.labwc.enable = lib.mkDefault true; }
          ];
        }
      );
    };

  flake.modules.homeManager.labwc =
    {
      config,
      lib,
      pkgs,
      nixosConfig,
      ...
    }:
    let
      cfg = config.my.programs.labwc;
      sessionService = description: command: {
        Unit = {
          Description = description;
          PartOf = [ "labwc-session.target" ];
          After = [ "labwc-session.target" ];
        };
        Service = {
          ExecStart = command;
          Restart = "on-failure";
        };
        Install.WantedBy = [ "labwc-session.target" ];
      };
    in
    {
      options.my.programs.labwc = {
        enable = lib.mkEnableOption "labwc configuration";
        outputModes = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Output names and display modes to apply when labwc starts.";
        };
      };

      config = lib.mkIf cfg.enable {
        wayland.windowManager.labwc = {
          enable = true;
          package = null;
          systemd.enable = true;
          systemd.variables = [
            "DISPLAY"
            "WAYLAND_DISPLAY"
            "XDG_CURRENT_DESKTOP"
            "XDG_SESSION_TYPE"
            "LABWC_PID"
            "XCURSOR_SIZE"
            "XCURSOR_THEME"
          ];
          environment = [
            "XCURSOR_SIZE=24"
            "XKB_DEFAULT_LAYOUT=us"
          ];
          rc = import ./settings.nix { inherit lib pkgs; };
          autostart = lib.mapAttrsToList (
            output: mode:
            "${lib.getExe pkgs.wlr-randr} ${
              lib.escapeShellArgs [
                "--output"
                output
                "--mode"
                mode
              ]
            }"
          ) cfg.outputModes;
        };

        # Home Manager starts the graphical target; stop it before the socket closes.
        xdg.configFile."labwc/shutdown" = {
          executable = true;
          text = ''
            #!${pkgs.runtimeShell}
            ${pkgs.systemd}/bin/systemctl --user stop graphical-session.target
          '';
        };
        systemd.user.services = {
          labwc-fcitx5 = sessionService "Fcitx5 for labwc" (lib.getExe nixosConfig.i18n.inputMethod.package);
          labwc-polkit = sessionService "Polkit authentication agent for labwc" "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        };
      };
    };
}
