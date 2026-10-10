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
      parfait = pkgs.callPackage ./parfait.nix { };
      bookmarkConfig = import ./bookmarks.nix { inherit lib; };
      containerConfig = import ./containers.nix { inherit lib; };
    in
    {
      options.my.programs.firefox.enable = lib.mkEnableOption "Firefox";

      config = lib.mkIf cfg.enable {
        programs.firefox = {
          enable = true;
          configPath = ".mozilla/firefox";

          profiles.nix = {
            inherit (bookmarkConfig) bookmarks;
            inherit (containerConfig) containers containersForce;

            extensions = import ./extensions.nix { inherit pkgs; } // {
              settings = containerConfig.extensionSettings // {
                "newtaboverride@agenedia.com" = {
                  force = true;
                  settings = {
                    type = "custom_url";
                    url = "https://home.yutakobayashi.com/";
                  };
                };
              };
            };

            isDefault = true;

            settings =
              let
                parfaitSrc = fetchTarball {
                  inherit (parfait) url;
                  sha256 = parfait.outputHash;
                };
                parfaitDefaults = lib.pipe "${parfaitSrc}/user.js" [
                  builtins.readFile
                  (lib.splitString "\n")
                  (map (builtins.match ''user_pref\("([^"]+)", (.*)\);''))
                  (lib.filter (m: m != null))
                  (map (m: lib.nameValuePair (lib.elemAt m 0) (builtins.fromJSON (lib.elemAt m 1))))
                  lib.listToAttrs
                ];
                parfaitOverrides = {
                  "parfait.theme.blur.enabled" = true;
                };
                staleOverrides = lib.attrNames (removeAttrs parfaitOverrides (lib.attrNames parfaitDefaults));
              in
              lib.throwIf (staleOverrides != [ ])
                "parfait's user.js no longer defines ${lib.concatStringsSep ", " staleOverrides}"
                (
                  parfaitDefaults
                  // parfaitOverrides
                  // {
                    "extensions.autoDisableScopes" = 0;

                    "sidebar.verticalTabs" = true;
                    "sidebar.visibility" = "hide-sidebar";

                    "browser.translations.automaticallyPopup" = false;
                    "layout.spellcheckDefault" = 0;
                    "signon.rememberSignons" = false;

                    "browser.toolbars.bookmarks.visibility" = "always";
                  }
                  // bookmarkConfig.settings
                );

            search = import ./search.nix { inherit pkgs; };
          };
        };

        home.file."${config.programs.firefox.profilesPath}/${config.programs.firefox.profiles.nix.path}/chrome".source =
          parfait;
      };
    };
}
