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
      bookmarkConfig = import ./bookmarks.nix { inherit lib; };
    in
    {
      options.my.programs.firefox.enable = lib.mkEnableOption "Firefox";

      config = lib.mkIf cfg.enable {
        programs.firefox = {
          enable = true;
          configPath = ".mozilla/firefox";

          profiles.nix = {
            inherit (bookmarkConfig) bookmarks;

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
            }
            // bookmarkConfig.settings;

            search = import ./search.nix { inherit pkgs; };
          };
        };
      };
    };
}
