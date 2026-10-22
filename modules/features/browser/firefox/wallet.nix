{ pkgs }:
{
  id = 1;
  name = "wallet";
  path = "wallet";
  isDefault = false;

  extensions.packages = [ pkgs.firefox-addons.metamask ];

  settings = {
    "extensions.autoDisableScopes" = 0;
    "identity.fxaccounts.enabled" = false;
    "signon.rememberSignons" = false;
    "browser.startup.homepage" = "about:blank";
    "browser.startup.page" = 0;
    "browser.newtabpage.enabled" = false;
    "browser.toolbars.bookmarks.visibility" = "always";
    "browser.privatebrowsing.autostart" = false;
  };

  bookmarks = {
    force = true;
    settings = [
      {
        name = "Wallet";
        toolbar = true;
        bookmarks =
          map
            (url: {
              name = "";
              inherit url;
            })
            [
              "https://app.uniswap.org/"
              "https://app.aave.com/"
              "https://app.safe.global/"
              "https://app.ens.domains/"
              "https://opensea.io/"
              "https://revoke.cash/"
            ];
      }
    ];
  };
}
