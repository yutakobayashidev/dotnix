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

                    "browser.urlbar.decodeURLsOnCopy" = true;
                    "browser.tabs.insertAfterCurrent" = true;
                    "browser.tabs.loadBookmarksInTabs" = true;

                    "mousewheel.with_control.action" = 1;
                    "full-screen-api.transition-duration.enter" = "0 0";
                    "full-screen-api.transition-duration.leave" = "0 0";

                    "pdfjs.scrollModeOnLoad" = 1;
                    "pdfjs.spreadModeOnLoad" = 1;
                    "pdfjs.externalLinkTarget" = 2;

                    "reader.content_width" = 9;
                    "reader.line_height" = 5;
                    "reader.font_type" = "sans-serif";
                    "media.autoplay.default" = 5;

                    "browser.search.separatePrivateDefault.enabled" = true;
                    "browser.search.separatePrivateDefault.featureGate" = true;

                    "permissions.default.camera" = 2;
                    "permissions.default.microphone" = 2;
                    "media.getusermedia.screensharing.enabled" = false;

                    "privacy.query_stripping.enabled" = true;
                    "privacy.query_stripping.enabled.pbmode" = true;
                    "privacy.query_stripping.strip_list" = "s t";
                  }
                  // bookmarkConfig.settings
                );

            search = import ./search.nix { inherit pkgs; };
          };
        };

        home.file."${config.programs.firefox.profilesPath}/${config.programs.firefox.profiles.nix.path}/chrome".source =
          pkgs.runCommand "firefox-chrome" { } ''
            cp -r ${parfait} "$out"
            chmod u+w "$out/userChrome.css"
            cat >> "$out/userChrome.css" <<'EOF'

            /* Keep long selections readable in Firefox's translation panel. */
            .translations-panel-view {
              width: 48em !important;
            }
            #select-translations-panel-text-area {
              height: 16em !important;
            }
            EOF
            chmod u+w "$out/userContent.css"
            printf '\n' >> "$out/userContent.css"
            cat ${./userContent.css} >> "$out/userContent.css"
          '';
      };
    };
}
