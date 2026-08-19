{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";

    profiles.nix = {
      extensions.packages = with pkgs.firefox-addons; [
        onepassword-password-manager
        wappalyzer
        nos2x-fox
        metamask
        ipfs-companion
        keepa
        instapaper-official
        refined-github
        wayback-machine
        zotero-connector
        are-na
        web-clipper-obsidian
        (buildFirefoxXpiAddon {
          pname = "librezam";
          version = "5.9";
          addonId = "Librezam@Librezam";
          url = "https://addons.mozilla.org/firefox/downloads/file/4752025/librezam-5.9.xpi";
          sha256 = "090247f0ded960f013f593d1894d75acfedf411d13071f96b49fb113eeef2a51";
          meta = {
            homepage = "https://github.com/FoxRefire/Librezam";
            description = "Open-source music recognition extension";
            license = pkgs.lib.licenses.agpl3Only;
            platforms = pkgs.lib.platforms.all;
          };
        })
        vimium
      ];

      isDefault = true;

      settings = {
        "browser.toolbars.bookmarks.visibility" = "always";
        "extensions.autoDisableScopes" = 0;
        "sidebar.verticalTabs" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };

      search = {
        default = "DuckDuckGo Lite";

        engines = {
          "DuckDuckGo Lite" = {
            urls = [
              {
                template = "https://lite.duckduckgo.com/lite/?q={searchTerms}";
              }
            ];
            icon = "https://duckduckgo.com/favicon.ico";
          };

          tw-lite = {
            name = "tw-lite Latest";
            urls = [
              {
                template = "https://tw-lite.home.yutakobayashi.com/search?q={searchTerms}&product=Latest&following=true";
              }
            ];
            definedAliases = [ "@tw" ];
          };

          nix-packages = {
            name = "Nix Packages";
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          nixos-wiki = {
            name = "NixOS Wiki";
            urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
            icon = "https://wiki.nixos.org/favicon.ico";
            definedAliases = [ "@nw" ];
          };

          noogle = {
            name = "noogle";
            urls = [ { template = "https://noogle.dev/q?term={searchTerms}"; } ];
            icon = "https://noogle.dev/favicon.png";
            definedAliases = [ "@noogle" ];
          };

          crates-io = {
            name = "crates.io";
            urls = [ { template = "https://crates.io/search?q={searchTerms}"; } ];
            icon = "https://crates.io/favicon.ico";
            definedAliases = [ "@crates" ];
          };

          npm = {
            name = "npm";
            urls = [ { template = "https://www.npmjs.com/search?q={searchTerms}"; } ];
            icon = "https://www.google.com/s2/favicons?domain=npmjs.com&sz=64";
            definedAliases = [ "@npm" ];
          };

          pypi = {
            name = "PyPI";
            urls = [ { template = "https://pypi.org/search/?q={searchTerms}"; } ];
            icon = "https://pypi.org/favicon.ico";
            definedAliases = [ "@pypi" ];
          };

          nixos-options = {
            name = "NixOS Options";
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@no" ];
          };

          docs-rs = {
            name = "docs.rs";
            urls = [ { template = "https://docs.rs/releases/search?query={searchTerms}"; } ];
            icon = "https://docs.rs/favicon.ico";
            definedAliases = [ "@docs" ];
          };

          grep-app = {
            name = "grep.app";
            urls = [ { template = "https://grep.app/search?q={searchTerms}"; } ];
            icon = "https://grep.app/favicon.ico";
            definedAliases = [ "@grep" ];
          };

          terraform-registry = {
            name = "Terraform Registry";
            urls = [ { template = "https://registry.terraform.io/search/providers?q={searchTerms}"; } ];
            icon = "https://registry.terraform.io/favicon.ico";
            definedAliases = [ "@tf" ];
          };
        };

        force = true;
      };
    };
  };
}
