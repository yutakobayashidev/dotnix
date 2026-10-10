_:

{
  flake.modules.homeManager.firefox =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.firefox;
    in
    {
      options.my.programs.firefox.enable = lib.mkEnableOption "Firefox";

      config = lib.mkIf cfg.enable {
        programs.firefox = {
          enable = true;
          configPath = ".mozilla/firefox";

          profiles.nix = {
            imports = [ ./bookmarks.nix ];

            extensions = import ./extensions.nix { inherit pkgs; };

            isDefault = true;

            settings = {
              "browser.toolbars.bookmarks.visibility" = "always";
              "extensions.autoDisableScopes" = 0;
              "sidebar.position_start" = true;
              "sidebar.revamp" = true;
              "sidebar.verticalTabs" = true;
              "sidebar.visibility" = "always-show";
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };

            search = import ./search.nix { inherit pkgs; };
          };
        };
      };
    };
}
