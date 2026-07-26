_:

{
  flake.modules.homeManager.xdg =
    { config, lib, ... }:
    let
      cfg = config.ext.xdg;
    in
    {
      options.ext.xdg.enable = lib.mkEnableOption "XDG desktop integration";

      config = lib.mkIf cfg.enable {
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "text/html" = "firefox.desktop";
            "x-scheme-handler/http" = "firefox.desktop";
            "x-scheme-handler/https" = "firefox.desktop";
            "x-scheme-handler/about" = "firefox.desktop";
            "x-scheme-handler/unknown" = "firefox.desktop";
          };
        };
      };
    };
}
