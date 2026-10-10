{ lib, ... }:
let
  # Only bookmarks tagged "shortcut" become new-tab tiles.
  tree = [
    {
      name = "Bookmarks Toolbar";
      toolbar = true;
      bookmarks = [
        # Development
        {
          name = "";
          url = "https://github.com/";
          tags = [ "shortcut" ];
        }
        {
          name = "";
          url = "https://git.yutakobayashi.com/";
        }
        {
          name = "";
          url = "https://search.nixos.org/packages";
        }
        {
          name = "";
          url = "https://wiki.nixos.org/";
        }
        {
          name = "";
          url = "https://noogle.dev/";
        }
        {
          name = "";
          url = "https://atcoder.jp/";
        }
        {
          name = "";
          url = "https://leetcode.com/";
        }
        {
          name = "";
          url = "https://regex101.com/";
        }
        {
          name = "";
          url = "https://www.uuidgenerator.net/";
        }

        # AI
        {
          name = "";
          url = "https://chatgpt.com/";
          tags = [ "shortcut" ];
        }
        {
          name = "";
          url = "https://claude.ai/new";
          tags = [ "shortcut" ];
        }
        {
          name = "";
          url = "https://gemini.google.com/";
        }
        {
          name = "";
          url = "https://grok.com/";
        }

        # Learning
        {
          name = "";
          url = "https://nlobby.nnn.ed.jp/home";
        }
        {
          name = "";
          url = "https://www.nnn.ed.nico/home";
        }
        {
          name = "";
          url = "https://www.eboard.jp/list/";
        }
        {
          name = "";
          url = "https://www.try-it.jp/";
        }
        {
          name = "";
          url = "https://ja.khanacademy.org/math";
        }
        {
          name = "";
          url = "https://www.geogebra.org/math?lang=ja";
        }
        {
          name = "";
          url = "https://www.wolframalpha.com/";
        }
        {
          name = "";
          url = "https://phet.colorado.edu/ja/";
        }
        {
          name = "";
          url = "https://www.duolingo.com/learn";
        }
        {
          name = "";
          url = "https://youglish.com/?lang=en";
        }
        {
          name = "";
          url = "https://apps.ankiweb.net/";
        }
        {
          name = "";
          url = "https://notebooklm.google.com/";
        }
        {
          name = "";
          url = "https://www.zotero.org/";
        }

        # Daily use and media
        {
          name = "";
          url = "https://search.home.yutakobayashi.com/";
        }
        {
          name = "";
          url = "https://linkding.home.yutakobayashi.com/";
          tags = [ "shortcut" ];
        }
        {
          name = "";
          url = "https://tw-lite.home.yutakobayashi.com/";
          tags = [ "shortcut" ];
        }
        {
          name = "";
          url = "https://cloud.home.yutakobayashi.com/";
        }
        {
          name = "";
          url = "https://photos.home.yutakobayashi.com/";
          tags = [ "shortcut" ];
        }
        {
          name = "";
          url = "https://music.home.yutakobayashi.com/";
          tags = [ "shortcut" ];
        }
        {
          name = "";
          url = "https://tv.home.yutakobayashi.com/tv/";
          tags = [ "shortcut" ];
        }
        {
          name = "";
          url = "https://ha.home.yutakobayashi.com/";
        }

        # Cloud and operations
        {
          name = "";
          url = "https://dash.cloudflare.com/";
        }
        {
          name = "";
          url = "https://console.cloud.google.com/";
        }
        {
          name = "";
          url = "https://grafana.home.yutakobayashi.com/";
        }
        {
          name = "";
          url = "https://status.home.yutakobayashi.com/";
        }
        {
          name = "";
          url = "https://n8n.home.yutakobayashi.com/";
        }

        # Bookmarklets
        {
          name = "WhatFont";
          url = "javascript:(function(){var d=document,s=d.createElement('scr'+'ipt'),b=d.body,l=d.location;s.setAttribute('src','http://chengyinliu.com/wf.js?o='+encodeURIComponent(l.href)+'&t='+(new Date().getTime()));b.appendChild(s)})();";
        }
        {
          name = "OG Image";
          url = ''javascript:(function(){const url=document.querySelector('meta[property="og:image"]')?.content;if(!url)return alert("No og:image on this page.");document.body.insertAdjacentHTML('beforeend',`<img src="''${url}" width="300" style="position:fixed;top:10px;left: 10px;z-index:9999;border:solid 2px #000;" onClick="this.remove()" >`);})();'';
        }
      ];
    }
  ];

  flatten = items: lib.concatMap (b: if b ? bookmarks then flatten b.bookmarks else [ b ]) items;

  forBookmarks = map (
    b:
    if b ? bookmarks then
      b // { bookmarks = forBookmarks b.bookmarks; }
    else
      builtins.removeAttrs b [
        "icon"
        "iconSize"
      ]
  );

  shortcuts = map (
    b:
    {
      inherit (b) url;
      label = b.name;
    }
    // lib.optionalAttrs (b ? icon) {
      smallFavicon = b.icon;
      favicon = b.icon;
      faviconSize = b.iconSize or 96;
    }
  ) (lib.filter (b: builtins.elem "shortcut" (b.tags or [ ])) (flatten tree));
in
{
  bookmarks = {
    force = true;
    settings = forBookmarks tree;
  };

  settings."browser.newtabpage.pinned" = builtins.toJSON shortcuts;
}
