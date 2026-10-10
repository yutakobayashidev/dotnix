{ pkgs }:
{
  packages = with pkgs.firefox-addons; [
    onepassword-password-manager
    containerise
    new-tab-override
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
      pname = "chatgpt-markdown-exporter";
      version = "0.3.2";
      addonId = "chatgpt-markdown-exporter@devcxl.cn";
      url = "https://addons.mozilla.org/firefox/downloads/file/5072774/chatgpt_markdown_exporter1-0.3.2.xpi";
      sha256 = "8443aa6ebff5811b7cb38ab199dbebf816136851a419bb4d21de30b0f300ef4b";
      meta = {
        homepage = "https://github.com/devcxl/chatgpt-markdown-exporter";
        description = "Export ChatGPT conversations as Markdown files";
        license = pkgs.lib.licenses.mit;
        platforms = pkgs.lib.platforms.all;
      };
    })
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
