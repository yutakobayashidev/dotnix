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
      ];

      isDefault = true;

      settings = {
        "browser.toolbars.bookmarks.visibility" = "always";
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
        };

        force = true;
      };
    };
  };
}
