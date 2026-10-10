{ pkgs }:
{
  packages = with pkgs.firefox-addons; [
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
}
